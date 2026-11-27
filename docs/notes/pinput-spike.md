# Spike UC-12.16 — `pinput` vs Implementação Própria

- **Data da consulta**: 2026-11-27
- **Veredito**: **`USAR_PINPUT`**
- **Impacto na UC-12.16**: **doc-only** (guia de integração `Pinput` + `KortexField`, sem novo widget em `kortex_widgets` e sem suíte TDD própria).

## Tabela de Critérios

| Critério | Avaliação (`pinput` >= 5.0.0 / ^8.0.0-beta.4) | Evidência / Fonte |
| --- | --- | --- |
| **Versão & Manutenção** | Ativo, null-safe, amplamente adotado no `pub.dev` | `pub.dev/packages/pinput` (consultado em 2026-11-27) |
| **Paste (Clipboard)** | Suporte nativo (long-press / menu contextual), distribuindo dígitos e disparando `onChanged` / `onCompleted` | `pub.dev/packages/pinput` |
| **Autofill SMS** | Suporte nativo via interface `SmsRetriever` (`smsRetriever:`), desacoplado de `smart_auth` (`^4.0.0`) desde `pinput` 5.0.0 | `pub.dev/packages/pinput` + `pub.dev/packages/smart_auth` |
| **Acessibilidade (`Semantics`)** | Leitores de tela (TalkBack/VoiceOver), `FocusNode` e anúncio de erro/validação integrados | `pub.dev/packages/pinput` |
| **Binding a `KortexField`** | Aceita `TextEditingController` externo + `onChanged: (v) => field.value = v` + `onCompleted` + `validator` sem fork | `pub.dev/packages/pinput` |
| **Peso de dependência** | Zero dependência nativa obrigatória (`smart_auth` é opt-in no app consumidor) | `pub.dev/packages/pinput` |

## Conclusão & Padrão de Integração

Como `pinput` atende integralmente paste, autofill SMS (opt-in via `SmsRetriever`), acessibilidade e binding direto com `KortexField<String>` sem fork, **não se justifica implementar nem manter um `OtpPinField` próprio** em `kortex_widgets`. A `UC-12.16` deve ser entregue apenas como documentação de integração.
