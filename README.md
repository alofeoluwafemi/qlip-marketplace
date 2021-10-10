## Setup

`.prettierrc` (.js & .sol supports)

```
{
  "semi": false,
  "singleQuote": true,
  "trailingComma": "es5",
  "arrowParens": "avoid",
  "printWidth": 120,
  "overrides": [
    {
      "files": "*.sol",
      "options": {
        "printWidth": 80,
        "tabWidth": 4,
        "useTabs": false,
        "singleQuote": false,
        "bracketSpacing": false,
        "explicitTypes": "always"
      }
    }
  ]
}

```

`.vscode/settings.json`

```
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "solidity.formatter": "prettier", // This is the default so it might be missing.
  "[solidity]": {
    "editor.defaultFormatter": "JuanBlanco.solidity"
  }
}
```

## Resources

https://github.com/prettier-solidity/prettier-plugin-solidity

## Verify contract using truffle

`truffle run verify <contract_name>@<contract_address> --network <network_name>`

truffle run verify QlipMarketPlace@0x92C0b4c1892842F8cCcA80109fE802b96e8E9a0A --network bsc_test