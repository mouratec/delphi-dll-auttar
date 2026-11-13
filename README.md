# delphi-dll-auttar

Implementação em Object Pascal (Delphi / Lazarus `i386-win32`) para integração com a biblioteca **Auttar CTFClient (`ctfclient.dll`)**, seguindo o **Manual de Integração CTFClient Biblioteca v1.83** e o **Manual de Códigos de Erro v1.05**.

## Operações Suportadas

- **Cartões (Crédito e Débito):**
  - `101` — Débito à Vista
  - `112` — Crédito à Vista
  - `113` — Crédito Parcelado (captura da quantidade de parcelas)
  - `120` — Crédito Digitado (captura opcional de cartão/vencimento)
- **PIX:**
  - `422` — Pagamento PIX com consulta (`7391=1` -> `7029` / `7390`) e exibição simultânea do QR Code na tela do PDV e no Pinpad
  - `423` — Consulta PIX (`7516` opcional / `7000` + `7015`)
  - `431` — Devolução PIX (`7516` opcional / `7000` + `7015`)
- **Cancelamento e Reimpressão:**
  - `128` — Cancelamento Genérico (NSU CTF e data original)
  - `012` — Reimpressão de Comprovante
- **Administrativas:**
  - `800` — Configuração do CTFClient
  - `801` — Autenticação HTTPS em tela única (Login `7917`, Senha `7918` e CNPJ `7919` enviados via `iniciaTransacaoCTFext`)

## Arquitetura e Fluxo de Integração

- **Ciclo completo da DLL:** `iniciaClientCTF` -> `iniciaTransacaoCTF` / `iniciaTransacaoCTFext` -> loop interativo `continuaTransacaoCTF` (comandos `00` a `09` e buffer `p_sc` de 99.000 bytes) -> `finalizaTransacaoCTF` / `finalizaTransacaoCTFext`.
- **Validação de Aprovação (`TTransactionResponse.Aprovada`):** valida retorno da DLL (`resultado = '00'`), subcampo `7000` (`'00'` ou `'13'`) e, para `423`/`431`, subcampo `7015 = '00'`.
- **Confirmação e Desfazimento:** operações financeiras confirmam com `confirmar = '1'` após exibição dos comprovantes (ou desfazem com `confirmar = '0'` quando permitido); operações administrativas/consultas (`800`, `801`, `012`, `423`) não disparam `finalizaTransacaoCTF`.
- **Auditoria e Diagnóstico:**
  - Exibição completa de todos os subcampos retornados pela DLL no painel do PDV ao final de cada operação (`NomeSubcampo`).
  - Log técnico em disco (`CTFDebug.log`) com stream persistente para mínimo impacto de I/O.

## Pré-requisitos

- **Lazarus IDE / Free Pascal** compilando para arquitetura **x86 (`i386-win32`)** (a `ctfclient.dll` da Auttar é 32-bit).
- **CTFClient Auttar** instalado, configurado e em execução na máquina.

## Estrutura do Projeto

- `AuttarTefProject.lpr` / `AuttarTefProject.lpi`: Ponto de entrada e configuração do projeto Lazarus (`i386-win32`).
- `mainform.pas`: Interface principal do PDV, exibição de comprovantes, janela de QR Code PIX e tabela de subcampos.
- `ctfintegration.pas`: Orquestração da máquina de estados do protocolo CTFClient (`TCtfIntegration`).
- `ctfclientlib.pas`: Carregamento dinâmico e assinaturas `stdcall` da `ctfclient.dll`.
- `ctfmodels.pas`: Modelos `TTransactionRequest` e `TTransactionResponse`.
- `CtfEnums.pas`: Constantes de operações, comandos (`00`–`09`), subcampos e descrições.
- `CtfLogger.pas`: Logger em arquivo (`CTFDebug.log`).
- `manual/`: Manuais oficiais Auttar de referência (Integração v1.83 e Códigos de Erro v1.05).

## Compilação

Pela IDE do Lazarus (abrindo `AuttarTefProject.lpi`) ou via linha de comando:

```powershell
C:\lazarus\lazbuild.exe -B AuttarTefProject.lpi
```
