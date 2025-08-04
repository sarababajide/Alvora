// alvora-synth-token.test.ts
import { describe, it, expect, beforeEach } from "vitest";

// Types
type Principal = string;
type Ticker = string;

interface SynthAsset {
  supply: bigint;
  owner: Principal;
  price: bigint;
}

interface MockAlvoraSynthToken {
  admin: Principal;
  paused: boolean;
  assets: Map<Ticker, SynthAsset>;
  balances: Map<string, bigint>; // ticker:owner -> balance
  collateral: Map<Principal, bigint>;
  fees: bigint;

  isAdmin: (caller: Principal) => boolean;
  getBalanceKey: (ticker: Ticker, owner: Principal) => string;
}

// Mock Contract Implementation
const alvora: MockAlvoraSynthToken = {
  admin: "STADMIN000000000000000000000000000000000000",
  paused: false,
  assets: new Map(),
  balances: new Map(),
  collateral: new Map(),
  fees: 10n,

  isAdmin(caller) {
    return caller === this.admin;
  },

  getBalanceKey(ticker, owner) {
    return `${ticker}:${owner}`;
  }
};

// Contract Functions
const registerAsset = (caller: Principal, ticker: Ticker, price: bigint) => {
  if (!alvora.isAdmin(caller)) return { error: "ERR_NOT_AUTHORIZED" };
  if (alvora.assets.has(ticker)) return { error: "ERR_ASSET_EXISTS" };
  alvora.assets.set(ticker, { supply: 0n, owner: caller, price });
  return { value: true };
};

const mint = (caller: Principal, ticker: Ticker, amount: bigint) => {
  const asset = alvora.assets.get(ticker);
  if (!asset) return { error: "ERR_ASSET_NOT_REGISTERED" };
  const key = alvora.getBalanceKey(ticker, caller);
  alvora.balances.set(key, (alvora.balances.get(key) || 0n) + amount);
  asset.supply += amount;
  return { value: true };
};

const burn = (caller: Principal, ticker: Ticker, amount: bigint) => {
  const asset = alvora.assets.get(ticker);
  if (!asset) return { error: "ERR_ASSET_NOT_REGISTERED" };
  const key = alvora.getBalanceKey(ticker, caller);
  const balance = alvora.balances.get(key) || 0n;
  if (balance < amount) return { error: "ERR_INSUFFICIENT_BALANCE" };
  alvora.balances.set(key, balance - amount);
  asset.supply -= amount;
  return { value: true };
};

const depositCollateral = (caller: Principal, amount: bigint) => {
  const prev = alvora.collateral.get(caller) || 0n;
  alvora.collateral.set(caller, prev + amount);
  return { value: true };
};

const withdrawCollateral = (caller: Principal, amount: bigint) => {
  const prev = alvora.collateral.get(caller) || 0n;
  if (prev < amount) return { error: "ERR_INSUFFICIENT_COLLATERAL" };
  alvora.collateral.set(caller, prev - amount);
  return { value: true };
};

// Tests
describe("Alvora Synth Token", () => {
  const user = "STUSER000000000000000000000000000000000000";
  const admin = alvora.admin;
  const ticker = "xUSD";

  beforeEach(() => {
    alvora.assets.clear();
    alvora.balances.clear();
    alvora.collateral.clear();
    alvora.paused = false;
  });

  it("should allow admin to register new asset", () => {
    const result = registerAsset(admin, ticker, 100n);
    expect(result).toEqual({ value: true });
    expect(alvora.assets.has(ticker)).toBe(true);
  });

  it("should not allow non-admin to register asset", () => {
    const result = registerAsset(user, ticker, 100n);
    expect(result).toEqual({ error: "ERR_NOT_AUTHORIZED" });
  });

  it("should mint synth tokens after registration", () => {
    registerAsset(admin, ticker, 100n);
    const result = mint(user, ticker, 500n);
    expect(result).toEqual({ value: true });

    const key = alvora.getBalanceKey(ticker, user);
    expect(alvora.balances.get(key)).toBe(500n);
  });

  it("should burn tokens correctly", () => {
    registerAsset(admin, ticker, 100n);
    mint(user, ticker, 500n);
    const result = burn(user, ticker, 200n);
    expect(result).toEqual({ value: true });

    const key = alvora.getBalanceKey(ticker, user);
    expect(alvora.balances.get(key)).toBe(300n);
  });

  it("should fail to burn more than balance", () => {
    registerAsset(admin, ticker, 100n);
    mint(user, ticker, 100n);
    const result = burn(user, ticker, 200n);
    expect(result).toEqual({ error: "ERR_INSUFFICIENT_BALANCE" });
  });

  it("should deposit collateral", () => {
    const result = depositCollateral(user, 1000n);
    expect(result).toEqual({ value: true });
    expect(alvora.collateral.get(user)).toBe(1000n);
  });

  it("should allow collateral withdrawal if balance sufficient", () => {
    depositCollateral(user, 1000n);
    const result = withdrawCollateral(user, 400n);
    expect(result).toEqual({ value: true });
    expect(alvora.collateral.get(user)).toBe(600n);
  });

  it("should reject withdrawal over collateral balance", () => {
    depositCollateral(user, 300n);
    const result = withdrawCollateral(user, 400n);
    expect(result).toEqual({ error: "ERR_INSUFFICIENT_COLLATERAL" });
  });
});
