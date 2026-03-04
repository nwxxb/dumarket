require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "vega"
  gem "pry"
end

require "vega"

def generate_median_charts_spec(main_label, metrics, data, base_transform)
  base = Vega.lite
    .data(data)
    .transform(base_transform)
    .mark(type: "bar", tooltip: true)
    .width(500)

  metrics.map do |metric|
    base.layer([
      {
        mark: {type: "bar", tooltip: true},
        encoding: {
          y: {
            field: main_label,
            type: "nominal",
            title: ""
          },
          yOffset: {field: "file_name"},
          color: {field: "file_name"},
          x: {
            field: metric,
            type: "quantitative",
            title: "median of #{metric}",
            scale: {type: "symlog"},
            aggregate: "median"
          }
        }
      },
      {
        mark: {type: "tick", color: "#db3752", thickness: 2, size: 10, tooltip: true},
        encoding: {
          y: {
            field: main_label,
            type: "nominal"
          },
          yOffset: {field: "file_name"},
          x: {
            field: metric,
            type: "quantitative",
            aggregate: "q3"
          },
          detail: {field: "file_name"}
        }
      },
      {
        mark: {type: "tick", color: "#99031c", thickness: 2, size: 10, tooltip: true},
        encoding: {
          y: {
            field: main_label,
            type: "nominal"
          },
          yOffset: {field: "file_name"},
          x: {
            field: metric,
            type: "quantitative",
            aggregate: "max"
          },
          detail: {field: "file_name"}
        }
      }
    ]).spec
  end
end

parsed_data = {
  web_lograge: [],
  docker_stats: []
}

charts = {
  web_lograge: nil,
  docker_stats: nil
}

# 1. web lograge
metrics = ["allocations", "duration", "view", "db"]

lograge_files = ["log/experiment_lograge_first.log"]
lograge_files.each do |file_name|
  File.open(file_name) do |f|
    f.each_line do |line|
      if /^\{..*\}$/.match?(line)
        cleaned_line = line.gsub("Controller", "")
          .gsub("DELETE", "DEL")
          .gsub("::", "/")
        parsed_line = JSON.parse(cleaned_line)
        parsed_line["file_name"] = f.path
        parsed_data[:web_lograge] << parsed_line
      end
    end
  end
end

charts[:web_lograge] = generate_median_charts_spec(
  "endpoint", metrics, parsed_data[:web_lograge],
  {calculate: "datum.method + ' ' + datum.controller + '#' + datum.action", as: "endpoint"}
)

# 2. docker_stats lograge
metrics = ["cpu", "mem"]

docker_stats_file = ["log/docker_stats_20260225_154053"]
docker_stats_file.each do |file_name|
  File.open(file_name) do |f|
    f.each_line do |line|
      if /^\{..*\}$/.match?(line)
        parsed_line = JSON.parse(line)
        parsed_line["file_name"] = f.path
        metrics.each do |metric|
          parsed_line[metric] = parsed_line[metric].to_f
        end
        parsed_data[:docker_stats] << parsed_line
      end
    end
  end
end

charts[:docker_stats] = generate_median_charts_spec(
  "container", metrics, parsed_data[:docker_stats],
  {filter: "indexof(datum.container, '--') < 0"}
)

# 3. compile all charts
final_charts = charts.values.flatten.each_slice(2).map do |chunk|
  Vega.lite.hconcat(chunk).spec
end

final_spec = Vega.lite.vconcat(final_charts)

template = <<~HTML
  <!doctype html>
  <html lang="en">
    <head>
      <title>The chart</title>
      <link href="css/style.css" rel="stylesheet" />
      <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    </head>
    <body>#{final_spec.to_html}</body>
  </html>
HTML

# Since you aren't in IRuby or a Rails View:
# This saves a standalone HTML file you can open in your browser!
File.write("overview.html", template)
puts "Chart generated! Open overview.html to see results."
