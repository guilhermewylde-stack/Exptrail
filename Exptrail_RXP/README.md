# Exptrail - Guias RestedXP

Pacote opcional de rotas para o addon Exptrail: Aliança, níveis 1 a 21, no WoW Forever.

Os guias são do projeto [RestedXP Guides](https://github.com/RestedXP/RXPGuides) e continuam sob a licença deles, [CC BY-NC-SA 4.0](LICENSE): uso não comercial, com atribuição e sob a mesma licença. Cada arquivo foi adaptado apenas na chamada de registro (veja `tools/import_rxp.py`); o texto das rotas está inalterado.

Este pacote é separado do Exptrail de propósito. O addon principal funciona sem ele e não contém conteúdo do RestedXP.

Para importar outro arquivo do RXPGuides:

```
python3 tools/import_rxp.py <RXPGuides>/Guides/forever Guides Horde-01-12_Durotar.lua
```

e acrescente o arquivo ao `Exptrail_RXP.toc`.
