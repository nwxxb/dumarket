import http from "k6/http";
import { sleep, check } from "k6";
import { SharedArray } from "k6/data";
import { CookieJar } from "k6/http";
import exec from "k6/execution";

const MAX_VUS = __ENV.VUS ? parseInt(__ENV.VUS) : 1
export const options = {
  scenarios: {
    warm_up: {
      executor: "per-vu-iterations",
      vus: 1,
      iterations: 1,
      maxDuration: "2m",
      startTime: "0s"
    },
    main_flow: {
      startTime: "1m",
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: MAX_VUS * 0.2 },
        { duration: "1m", target: MAX_VUS * 0.2 },
        { duration: "30s", target: MAX_VUS * 0.4 },
        { duration: "1m", target: MAX_VUS * 0.4 },
        { duration: "30s", target: MAX_VUS * 0.6 },
        { duration: "1m", target: MAX_VUS * 0.6 },
        { duration: "30s", target: MAX_VUS * 0.8 },
        { duration: "1m", target: MAX_VUS * 0.8 },
        { duration: "30s", target: MAX_VUS },
        { duration: "1m", target: MAX_VUS },
        { duration: "1m", target: 0 }
      ]
    }
  },
};

const BASE_URL = "http://localhost:3000";
const PRODUCT_SHOW_VISIT_TIMES = 3;

let users;
try {
  users = new SharedArray("users", function () {
    return JSON.parse(open("../tmp/segmented_users.json"));
  });
} catch (e) {
  console.warn(
    "can't parse tmp/segmented_users json file, fallback to only admin as VU",
  );
  users = new SharedArray("users", function () {
    return [
      {
        email: "admin@dumarket.com",
        is_admin: true,
        password: "password123",
      },
    ];
  });
}

let userProducts;
let adminProducts;
try {
    userProducts = new SharedArray("userProducts", function() {
        return JSON.parse(open("../tmp/segmented_products.json"))["user_products"]
    })
    adminProducts = new SharedArray("adminProducts", function() {
        return JSON.parse(open("../tmp/segmented_products.json"))["admin_products"]
    })
} catch (e) {
    throw new Error("can't parse tmp/segmented_products json file")
}

// {
//    method
//    action
//    authenticityToken
//    targetItemId: optional
// }
function extractAllFormData(html) {
  const forms = [];
  const formRegex =
    /<form[^>]*action="(?<action>[^"]+)"[^>]*>(?<formBody>[\s\S]*?)<\/form>/gi;

  let formMatch;
  while ((formMatch = formRegex.exec(html)) !== null) {
    const action = formMatch[1];
    const formBody = formMatch[2];
    const lastUrlParamsID = action.match(/(\d+)$/)?.[1] || "";
    const altMethodMatch = formBody.match(/name="_method"[^>]*value="([^"]+)"/);
    const tokenMatch = formBody.match(
      /name="authenticity_token"[^>]*value="([^"]+)"/,
    );
    const inputs = {};
    const inputRegex = /<input[^>]*>/gi;

    let inputMatch;
    while ((inputMatch = inputRegex.exec(formBody)) !== null) {
      const input = inputMatch[0];
      const nameMatch = input.match(/name="([^"]+)"/);
      const valueMatch = input.match(/value="([^"]+)"/);

      if (nameMatch && valueMatch) {
        inputs[nameMatch[1]] = valueMatch[1];
      }
    }

    forms.push({
      altMethod: altMethodMatch ? altMethodMatch[1] : "post",
      authenticityToken: tokenMatch ? tokenMatch[1] : null,
      action: action,
      lastUrlParamsID: lastUrlParamsID,
      inputs: inputs,
    });
  }

  return forms;
}

function extractAllHref(html) {
  const links = [];
  const linkRegex = /<a[^>]*href="(?<fullHref>[^"]+)"[^>]*>/gi;

  let linkMatch;
  while ((linkMatch = linkRegex.exec(html)) !== null) {
    const href = linkMatch[1];
    const lastUrlParamsID = href.match(/(\d+)$/)?.[1] || "";

    links.push({
      href: href,
      lastUrlParamsID: lastUrlParamsID,
    });
  }

  return links;
}

function extractMetaCSRF(html) {
  const match = html.match(/<meta name="csrf-token" content="([^"]+)"/);
  return match ? match[1] : null;
}

export default function () {
  const userIndex = (exec.vu.idInTest - 1) % users.length;
  const user = users[userIndex];
  console.log("user: ", user.email, `${userIndex}`)
  const jar = new CookieJar();
  const params = { jar };
  // 1. Products#index
  let res = http.get(BASE_URL, params);
  check(res, {
    "products#index page loaded": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);

  let form;
  let links;
  let link;
  let payload;
  let randomProductIds = [...userProducts]
    .sort(() => Math.random() - 0.5)
    .slice(0, PRODUCT_SHOW_VISIT_TIMES)
  for (let i = 0; i < PRODUCT_SHOW_VISIT_TIMES; i++) {
    // 2. Products#show
    const randomProductId = randomProductIds[i]
    res = http.get(`${BASE_URL}/products/${randomProductId}`, params);
    check(res, {
      "products#show page loaded": (res) =>
        res.status >= 200 && res.status < 400,
    });
    sleep(1);

    // 3. CartItems#create
    form = extractAllFormData(res.body).find((f) => {
      return f.altMethod === "post" && f.action === "/cart/items";
    });

    payload = {
      authenticity_token: form.authenticityToken,
      product_id: randomProductId,
    };

    res = http.post(`${BASE_URL}/cart/items`, payload, params);
    check(res, {
      "cart_items#create sent payload": (res) =>
        res.status >= 200 && res.status < 400,
    });
    sleep(1);
  }

  // 4. CartItems#index
  res = http.get(`${BASE_URL}/cart/items`, params);
  check(res, {
    "cart_items#index page loaded": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);

  // 5. CartItems#update
  form = extractAllFormData(res.body).find((f) => f.altMethod === "put");

  payload = {
    authenticity_token: form.authenticityToken,
    "cart_item[subaction]": "increase",
  };

  res = http.put(
    `${BASE_URL}/cart/items/${form.lastUrlParamsID}`,
    payload,
    params,
  );
  check(res, {
    "cart_items#update sent payload": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);

  // 6. CartItems#destroy
  res = http.get(`${BASE_URL}/cart/items`, params);

  form = extractAllFormData(res.body).find((f) => f.altMethod === "delete");
  payload = {
    authenticity_token: form.authenticityToken,
  };

  res = http.del(
    `${BASE_URL}/cart/items/${form.lastUrlParamsID}`,
    payload,
    params,
  );
  check(res, {
    "cart_items#destroy sent payload": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);

  // 7. Users/Sessions#new
  res = http.get(`${BASE_URL}/users/sign_in`, params);
  check(res, {
    "users/sessions#new page loaded": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);

  // 8. Users/Sessions#create
  form = extractAllFormData(res.body).find((f) => f.altMethod === "post");
  payload = {
    authenticity_token: form.authenticityToken,
    "user[email]": user.email,
    "user[password]": user.password,
    "user[remember_me]": "0",
    commit: "Log+in",
  };
  res = http.post(`${BASE_URL}/users/sign_in`, payload, params);
  check(res, {
    "users/sessions#create sent payload": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);

  // 9. Orders#new
  res = http.get(`${BASE_URL}/orders/new`, params);
  check(res, {
    // "orders#new page loaded": (res) => res.status >= 200 && res.status < 400,
    // if carts is empty, then it will redirect to cart/items
    // we want to test the positive path here, so it's not pass the check
    "orders#new page loaded": (res) => res.status >= 200 && res.status < 300,
  });
  sleep(1);

  // 10. Orders#create
  form = extractAllFormData(res.body).find((f) => f.altMethod === "post");
  payload = {
    authenticity_token: form.authenticityToken,
    "order[cart_signature]": form.inputs["order[cart_signature]"],
    "order[customer_name]": `${user.email} VU ${__VU}`,
    "order[customer_address]": `${user.email} address for VU ${__VU}`,
  };

  res = http.post(`${BASE_URL}/orders`, payload, params);
  check(res, {
    "orders#create sent payload": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);

  // 11. Orders#index
  res = http.get(`${BASE_URL}/orders`, params);
  check(res, {
    "orders#index page loaded": (res) => res.status >= 200 && res.status < 400,
  });
  sleep(1);

  // 12. Orders#show
  link = extractAllHref(res.body).find((l) => /\/orders\/\d+/.test(l.href));
  res = http.get(`${BASE_URL}${link.href}`, params);
  check(res, {
    "orders#show page loaded": (res) => res.status >= 200 && res.status < 400,
  });
  sleep(1);

  // 13. Users/Registrations#show
  res = http.get(`${BASE_URL}/users/show`, params);
  check(res, {
    "users/registrations#show page loaded": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);

  if (user.is_admin) {
    // 1. Admin/Products#index
    res = http.get(`${BASE_URL}/admin/products`, params);
    check(res, {
      "admin/products#index page loaded": (res) =>
        res.status >= 200 && res.status < 400,
    });
    sleep(1);

    // 2. Admin/Products#new
    res = http.get(`${BASE_URL}/admin/products/new`, params);
    check(res, {
      "admin/products#new page loaded": (res) =>
        res.status >= 200 && res.status < 400,
    });
    sleep(1);

    // 3. Admin/Products#create
    form = extractAllFormData(res.body).find((f) => f.altMethod === "post");
    payload = {
      authenticity_token: form.authenticityToken,
      "product[name]": `product ${__VU}`,
      "product[description]": `description for product ${__VU}`,
      "product[price_cents]": `${__VU}`,
    };
    res = http.post(`${BASE_URL}/admin/products`, payload, params);
    check(res, {
      "admin/products#create sent payload": (res) =>
        res.status >= 200 && res.status < 400,
    });
    sleep(1);

    let startIndex = exec.scenario.iterationInTest * PRODUCT_SHOW_VISIT_TIMES % adminProducts.length
    let randomProductIds = [...adminProducts]
        .slice(startIndex, startIndex + PRODUCT_SHOW_VISIT_TIMES)
    for (let i = 0; i < PRODUCT_SHOW_VISIT_TIMES; i++) {
      // 4. Admin/Products#show
      const randomProductId = randomProductIds[i]
      res = http.get(`${BASE_URL}/admin/products/${randomProductId}`, params);
      check(res, {
        "admin/products#show page loaded": (res) =>
          res.status >= 200 && res.status < 400,
      });
      sleep(1);

      // 5. Admin/Products#edit
      res = http.get(
        `${BASE_URL}/admin/products/${randomProductId}/edit`,
        params,
      );
      check(res, {
        "admin/products#edit page loaded": (res) =>
          res.status >= 200 && res.status < 400,
      });
      sleep(1);

      // 6. Admin/Products#update
      form = extractAllFormData(res.body).find((f) => f.altMethod === "put");

      payload = {
        authenticity_token: form.authenticityToken,
        "cart_item[subaction]": "increase",
        "product[name]": `product ${__VU} updated`,
        "product[description]": `description for product ${__VU} updated`,
        "product[price_cents]": `${__VU + 1}`,
      };

      res = http.put(
        `${BASE_URL}/admin/products/${randomProductId}`,
        payload,
        params,
      );
      check(res, {
        "admin/products#update sent payload": (res) =>
          res.status >= 200 && res.status < 400,
      });
      sleep(1);

      // 6. Admin/Products#destroy
      res = http.del(`${BASE_URL}/admin/products/${randomProductId}`, null, {
        ...params,
        headers: {
          "X-CSRF-Token": extractMetaCSRF(res.body),
        },
        redirects: 10,
      });
      check(res, {
        "admin/products#destroy done": (res) =>
          res.status >= 200 && res.status < 400,
      });
      sleep(1);
    }

    // 7. Admin/Orders#index
    res = http.get(`${BASE_URL}/admin/orders`, params);
    check(res, {
      "admin/orders#index page loaded": (res) =>
        res.status >= 200 && res.status < 400,
    });
    sleep(1);

    // 8. Admin/Orders#show
    link = extractAllHref(res.body).find((l) =>
      /\/admin\/orders\/\d+/.test(l.href),
    );
    res = http.get(`${BASE_URL}${link.href}`, params);
    check(res, {
      "admin/orders#show page loaded": (res) =>
        res.status >= 200 && res.status < 400,
    });
    sleep(1);

    // 9. Admin/Orders#update
    form = extractAllFormData(res.body).find((f) => f.altMethod === "put");

    payload = {
      authenticity_token: form.authenticityToken,
      "order[status]": "completed",
    };

    res = http.put(`${BASE_URL}${link.href}`, payload, params);
    check(res, {
      "admin/orders#update sent payload": (res) =>
        res.status >= 200 && res.status < 400,
    });
    sleep(1);
  }

  // 14. Users/Sessions#destroy
  res = http.del(`${BASE_URL}/users/sign_out`, null, {
    ...params,
    headers: {
      "X-CSRF-Token": extractMetaCSRF(res.body),
    },
    redirects: 10,
  });
  check(res, {
    "users/sessions#destroy done": (res) =>
      res.status >= 200 && res.status < 400,
  });
  sleep(1);
}
