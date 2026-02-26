import { createTamagui, createTokens } from "tamagui";
import { config as configBase } from "@tamagui/config/v3";

const tokens = createTokens({
  ...configBase.tokens,
});

export const config = createTamagui({
  ...configBase,
  tokens,
});

export type AppConfig = typeof config;

declare module "tamagui" {
  interface TamaguiCustomConfig extends AppConfig {}
}

export default config;
