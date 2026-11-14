#!/usr/bin/env python3
"""Converte arquivos de guia do RXPGuides para o Exptrail.

Uso: import_rxp.py <pasta Guides/forever do RXPGuides> <pasta de saída> <arquivo.lua>...

O conteúdo dos guias não é alterado. Só troca a chamada de registro e remove
a linha que depende de variáveis globais do addon original.
"""
import pathlib
import sys

HEADER = """-- Guia do projeto RestedXP Guides (https://github.com/RestedXP/RXPGuides),
-- arquivo original: Guides/forever/{name}
-- Licença: CC BY-NC-SA 4.0. Adaptado para o Exptrail: trocada a chamada de
-- registro e removida a checagem de idioma; o texto do guia está inalterado.
"""


def convert(text: str) -> str:
    lines = [line for line in text.splitlines() if "RXP.enabledLocale" not in line]
    return "\n".join(lines).replace("RXPGuides.RegisterGuide(", "Exptrail.RegisterRXP(") + "\n"


def main() -> None:
    source, target = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    target.mkdir(parents=True, exist_ok=True)
    for name in sys.argv[3:]:
        text = (source / name).read_text(encoding="utf-8")
        (target / name).write_text(HEADER.format(name=name) + convert(text), encoding="utf-8")
        print("ok", name)


if __name__ == "__main__":
    main()
