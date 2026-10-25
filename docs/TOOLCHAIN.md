# Toolchain fixada

- Godot: `4.7.2.stable.official.ed1daf0bf`.
- Executável local: `/home/otavio/Downloads/Apps/Godot_v4.7.2-stable_linux.x86_64`.
- SHA-256 do executável: `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`.
- Origem: [release oficial 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable).
- O ZIP Linux já instalado foi comparado com `SHA512-SUMS.txt` da release: `9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65`.
- Templates oficiais `Godot_v4.7.2-stable_export_templates.tpz` conferidos pelo mesmo manifesto SHA-512: `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079`.
- Instalados somente templates Linux/Windows x86_64 debug/release e `version.txt` em `~/.local/share/godot/export_templates/4.7.2.stable/`.

Os arquivos da engine/templates ficam fora do Git. Não atualizar automaticamente. Os scripts aceitam `GODOT_BIN` e recusam versões diferentes de 4.7.2 stable. Para reproduzir em outra máquina, obter essa release, conferir seu manifesto e instalar os templates correspondentes.
