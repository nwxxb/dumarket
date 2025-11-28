export {};

export const recentDate = (maxSecondsAgo = 5) => ({
  asymmetricMatch(received: string | Date) {
    const date = new Date(received);
    if (typeof date == 'number' && isNaN(date)) {
      return false;
    }
    const secondsAgo = (Date.now() - date.getTime()) / 1000;
    return secondsAgo >= 0 && secondsAgo <= maxSecondsAgo;
  },
  toString() {
    return `recentDate(${maxSecondsAgo})`;
  },
});

expect.extend({
  toBeRecentDate(received: Date, maxSecondsAgo: number = 5) {
    const secondsAgo = (Date.now() - received.getTime()) / 1000;
    const pass = secondsAgo >= 0 && secondsAgo <= maxSecondsAgo;

    return {
      pass,
      message: () => {
        return pass
          ? `Expected ${received} not to be within ${maxSecondsAgo} seconds ago`
          : `Expected ${received} to be within ${maxSecondsAgo} seconds ago, but it was ${secondsAgo.toFixed(2)} seconds ago`;
      },
    };
  },
});

declare global {
  namespace jest {
    interface Matchers<R> {
      toBeRecentDate(maxSecondsAgo?: number): R;
    }
  }
}
