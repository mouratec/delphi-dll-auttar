unit CtfEnums;

{ Dicionário de Integração Oficial Auttar - Delphi / Lazarus
  Alinhado ao Manual de Integração CTFClient Biblioteca v1.83
  e Manual de Códigos de Erro do CTFClient v1.05 }

{$mode delphi}

interface

const
  { --- RETORNOS DAS FUNÇÕES DA DLL (Parâmetro: resultado - Anexo I) --- }
  RET_SUCESSO                              = '00'; // Execução bem-sucedida da função
  RET_BIBLIOTECA_NAO_INICIALIZADA_CONT     = '50'; // Biblioteca não inicializada na continuaTransacaoCTF
  RET_ERRO_CONEXAO_INIT                    = '54'; // Erro ao estabelecer conexão na iniciaClientCTF
  RET_CTFCLIENT_HOME_NAO_CONFIG            = '59'; // Variável de ambiente CTFCLIENT_HOME não configurada
  RET_BIBLIOTECA_NAO_INICIALIZADA_FIN      = '84'; // Biblioteca não inicializada na finalizaTransacaoCTF
  RET_BIBLIOTECA_NAO_INICIALIZADA_INI      = '85'; // Biblioteca não inicializada na iniciaTransacaoCTF
  RET_AGUARDANDO_ACAO                      = '99'; // AC deve executar o comando retornado

  { --- CÓDIGOS DE RETORNO DA TRANSAÇÃO (Subcampo 7000 - Manual de Erros v1.05) --- }
  SC7000_APROVADA                          = '00'; // Execução bem-sucedida / transação aprovada
  SC7000_TIMEOUT                           = '01'; // Time out da transação
  SC7000_NAO_INICIALIZADA                  = '02'; // Apitef não inicializada
  SC7000_ERRO_PARAMETRO                    = '04'; // Erro nos parâmetros / integração (detalhe em 7300)
  SC7000_NAO_AUTORIZADA                    = '05'; // Transação não autorizada pela credenciadora
  SC7000_ERRO_COMUNICACAO                  = '10'; // Erro de comunicação da Apitef
  SC7000_ERRO_CTF                          = '11'; // Erro no CTF
  SC7000_ERRO_INTERTEF                     = '12'; // Erro na camada Intertef da Apitef
  SC7000_MULTITRANSACAO_PENDENTE           = '13'; // Transação confirmada, mas ainda existem outras a confirmar
  SC7000_ERRO_CRIPTOGRAFIA                 = '16'; // Erro de criptografia da mensagem
  SC7000_ERRO_FORMATACAO                   = '17'; // Erro de formatação da mensagem
  SC7000_NAO_HA_TRANSACAO                  = '18'; // Não há transação para ser confirmada
  SC7000_DADOS_INVALIDOS                   = '20'; // Dados de entrada inválidos (detalhe em 7300)

  { --- COMANDOS (Parâmetro: comando - Anexo II) --- }
  CMD_RECUPERAR_SUBCAMPO                   = '00'; // AC deve recuperar o subcampo retornado
  CMD_EXIBIR_MENSAGEM                      = '01'; // AC deve exibir mensagem de display
  CMD_EXIBIR_TITULO                        = '02'; // AC deve exibir o título do menu/texto
  CMD_LIMPAR_DISPLAY                       = '03'; // AC deve limpar o display
  CMD_OBTER_CONFIRMACAO                    = '04'; // AC deve obter confirmação SIM/NÃO
  CMD_EXIBIR_MENU                          = '05'; // AC deve exibir as opções de menu
  CMD_AGUARDAR_TECLA                       = '06'; // AC deve aguardar uma tecla ser pressionada
  CMD_CAPTURAR_DADO                        = '07'; // AC deve capturar um dado no teclado
  CMD_VERIFICAR_CANCELAR                   = '08'; // AC consultada para verificar cancelamento
  CMD_MENU_TEMPORIZADO                     = '09'; // AC deve exibir menu temporizado

  { --- OPERAÇÕES (Parâmetro: operacao - Anexo V) --- }
  OP_REIMPRESSAO                           = '012'; // Reimpressão do Último Comprovante
  OP_DEBITO                                = '101'; // Débito
  OP_CREDITO                               = '112'; // Crédito
  OP_PARCELADO_ADM                         = '113'; // Crédito Parcelado Sem Juros
  OP_PARCELADO_LOJ                         = '114'; // Crédito Parcelado Com Juros
  OP_CREDITO_DIGITADO                      = '120'; // Crédito Digitado
  OP_CANCELAMENTO_GENERICO                 = '128'; // Cancelamento Genérico
  OP_CONSULTA_MULTI_EC                     = '329'; // Consulta de Estabelecimentos Multi-EC
  OP_CARGA_TABELAS                         = '400'; // Carga de Tabelas
  OP_QR_CODE_PAGAMENTO                     = '420'; // Pagamento com QR Code
  OP_PIX_PAGAMENTO                         = '422'; // Pagamento Pix
  OP_PIX_CONSULTA                          = '423'; // Consulta Pix
  OP_STATUS_TRANSACAO                      = '426'; // Consulta de Status de Transação
  OP_PIX_DEVOLUCAO                         = '431'; // Devolução Pix
  OP_CONFIGURACAO                          = '800'; // Configuração do CTFClient
  OP_AUTENTICACAO                          = '801'; // Autenticação https do terminal
  OP_CAPTURA_PINPAD                        = '908'; // Captura de dados no pinpad
  OP_INFO_PINPAD                           = '909'; // Obtém informações gerais sobre o pinpad

  { --- SUBCAMPOS (Parâmetro: num_sc / dados - Anexo III) --- }
  SC_RESULTADO_TRANSACAO                   = '7000'; // Código de retorno da transação (00=Aprovado)
  SC_VALOR_TRANSACAO                       = '7005'; // Valor da transação em centavos
  SC_CARTAO_DIGITADO                       = '7006'; // Número do cartão digitado
  SC_QTD_PARCELAS                          = '7008'; // Número de parcelas
  SC_DATA_VENCIMENTO                       = '7010'; // Data de vencimento do cartão (MMAA)
  SC_NSU_ORIGINAL                          = '7012'; // NSU CTF da transação original
  SC_CODIGO_RESPOSTA                       = '7015'; // Código de resposta da credenciadora
  SC_DADOS_VARIAVEIS                       = '7029'; // Dados de retorno variável / caminho QR Code Pix
  SC_NSU_CTF                               = '7031'; // NSU do CTF
  SC_CVV                                   = '7039'; // Código de segurança do cartão
  SC_NSU_AUTORIZADORA                      = '7081'; // NSU da autorizadora
  SC_DATA_ORIGINAL                         = '7161'; // Data da transação original (DDMMAA)
  SC_CODIGO_ERRO                           = '7300'; // Código de erro (0000 quando sem erro)
  SC_CUPOM_CLIENTE                         = '7302'; // 1ª via do cupom de TEF – via do cliente
  SC_CUPOM_LOJISTA                         = '7303'; // 2ª via do cupom de TEF – via do lojista
  SC_REIMPRESSAO_CLIENTE                   = '7304'; // 1ª via de reimpressão – via do cliente
  SC_REIMPRESSAO_LOJISTA                   = '7305'; // 2ª via de reimpressão – via do lojista
  SC_ULTIMOS_4_DIGITOS                     = '7324'; // 4 últimos dígitos do cartão
  SC_NSU_AUTORIZADORA_ALFA                 = '7381'; // NSU da autorizadora alfanumérico
  SC_CUPOM_REDUZIDO                        = '7384'; // Cupom reduzido
  SC_MENSAGEM_DISPLAY                      = '7385'; // Mensagem de display da transação
  SC_VALOR_DESCONTO                        = '7387'; // Valor do desconto monetário
  SC_BANDEIRA_CARTAO                       = '7389'; // Nome da bandeira do cartão
  SC_ID_CONSULTA                           = '7390'; // Identificador da consulta (QR Code / Pix)
  SC_FLAG_CONSULTA                         = '7391'; // Flag consulta (QR Code / Pré-pago)
  SC_PIX_ID                                = '7516'; // Identificador da transação Pix
  SC_PIX_PSP                               = '7517'; // PSP – Prestador do Serviço de Pagamento Pix
  SC_CODIGO_AUTORIZACAO                    = '7564'; // Código de autorização (substitui 7095; no Pix retorna EndToEndId)
  SC_AUTH_LOGIN                            = '7917'; // Login para autenticação do terminal
  SC_AUTH_SENHA                            = '7918'; // Senha para autenticação do terminal
  SC_AUTH_CNPJ                             = '7919'; // CNPJ para autenticação do terminal
  SC_NOME_TRANSACAO                        = '7948'; // Nome da transação

function OperacaoExigeFinalizacao(AOperacao: Integer): Boolean;
function OperacaoPermiteDesfazimento(AOperacao: Integer): Boolean;
function OperacaoSemValor(AOperacao: Integer): Boolean;
function NomeSubcampo(const num_sc: string): string;

implementation

uses SysUtils;

function NomeSubcampo(const num_sc: string): string;
var
  Cod: Integer;
begin
  Cod := StrToIntDef(num_sc, -1);
  case Cod of
    7000: Result := 'Código de retorno da transação';
    7001: Result := 'Código da transação CTF';
    7005: Result := 'Valor da transação';
    7006: Result := 'Número do cartão';
    7008: Result := 'Número de parcelas';
    7010: Result := 'Data de vencimento do cartão';
    7011: Result := 'Código da autorizadora';
    7012: Result := 'NSU CTF da transação original';
    7015: Result := 'Código de resposta';
    7029: Result := 'Dados variáveis / QR Code';
    7031: Result := 'NSU CTF';
    7081: Result := 'NSU da autorizadora';
    7095: Result := 'Código de aprovação (depreciado)';
    7161: Result := 'Data da transação original';
    7300: Result := 'Código de erro';
    7302: Result := '1ª via cupom TEF (cliente)';
    7303: Result := '2ª via cupom TEF (lojista)';
    7304: Result := '1ª via reimpressão (cliente)';
    7305: Result := '2ª via reimpressão (lojista)';
    7306: Result := 'Nome da autorizadora';
    7308: Result := 'Nome da VAN';
    7311: Result := 'Data da transação (DDMMAAAA)';
    7312: Result := 'Hora da transação (HHMMSS)';
    7315: Result := 'Valor total da transação';
    7324: Result := '4 últimos dígitos do cartão';
    7381: Result := 'NSU autorizadora alfanumérico';
    7384: Result := 'Cupom reduzido';
    7385: Result := 'Mensagem de display';
    7387: Result := 'Valor do desconto monetário';
    7388: Result := 'Tipo captura pré-autorização';
    7389: Result := 'Nome da bandeira';
    7390: Result := 'Identificador consulta';
    7391: Result := 'Flag consulta';
    7516: Result := 'Identificador transação Pix';
    7517: Result := 'PSP Pix';
    7564: Result := 'Código de autorização (cAut)';
    7917: Result := 'Login autenticação terminal';
    7918: Result := 'Senha autenticação terminal';
    7919: Result := 'CNPJ autenticação terminal';
    7939: Result := 'Método verificação portador';
    7942: Result := 'Nome da rede adquirente';
    7943: Result := 'Código da VAN alfanumérico';
    7947: Result := 'Status transação consultada';
    7948: Result := 'Nome da transação';
    7949: Result := 'Código transação original';
    7963: Result := 'Número de série pinpad';
    7964: Result := 'Fabricante pinpad';
    7965: Result := 'Modelo hardware pinpad';
    7966: Result := 'Versão especificação pinpad';
    7967: Result := 'Versão firmware pinpad';
    7968: Result := 'Versão aplicação básica pinpad';
    7969: Result := 'Retorno GetInfo pinpad';
    7971: Result := 'Card_id (cartão tokenizado)';
  else
    Result := 'Subcampo (ver Anexo III)';
  end;
end;

function OperacaoExigeFinalizacao(AOperacao: Integer): Boolean;
begin
  case AOperacao of
    12,  // Reimpressão do Último Comprovante
    110, // Consulta CDC c/ Parcela à Vista
    111, // Consulta CDC s/ Parcela à Vista
    118, // Consulta Crédito
    126, // Consulta Crédito Digitado
    129, // Consulta Cheque
    139, // Consulta AVS
    141, // Consulta de Cash Private Label
    144, // Consulta Private Label
    145, // Consulta Private Label Digitado
    172, // Consulta Analítica SPC
    173, // Consulta de Valores de Recarga de Celular
    180, // Consulta de Título
    181, // Consulta de Arrecadação
    182, // Consulta de Fatura
    226, // Consulta Cartão
    228, // Consulta de configuração
    229, // Reimpressão de Outro Comprovante
    250, // Consulta de saldo de débito
    251, // Consulta de saldo de crédito
    263, // Consulta Cartão Presente
    266, // Consulta Transferência Doméstica
    268, // Simulação de crediário com cartão de débito
    270, // Simulação de crediário com cartão de crédito
    288, // Consulta Saldo Auto
    291, // Consulta Saldo Dotz
    301, // Identificação de Cartão Associado
    321, // Consulta de Cartão Presente
    329, // Consulta de Estabelecimentos Multi-EC
    400, // Carga de Tabelas
    423, // Consulta Pix
    426, // Consulta de Status de Transação
    431, // Devolução Pix
    800, // Configuração do CTFClient
    801, // Autenticação https do terminal
    908, // Captura de dados no pinpad
    909: // Obtém informações do pinpad
      Result := False;
  else
    Result := True;
  end;
end;

function OperacaoPermiteDesfazimento(AOperacao: Integer): Boolean;
begin
  // Conforme Manual v1.83: apenas operações que exigem finalizaTransacaoCTF podem ser
  // desfeitas (confirmar = '0'), com exceção explícita da operação 422 (Pagamento Pix),
  // que exige confirmação e não pode ser desfeita nem cancelada.
  Result := OperacaoExigeFinalizacao(AOperacao) and (AOperacao <> 422);
end;

function OperacaoSemValor(AOperacao: Integer): Boolean;
begin
  // Operações administrativas, de configuração ou de consulta que iniciam com valor zerado
  // ou dispensam cobrança financeira obrigatória no PDV.
  case AOperacao of
    12,
    110, 111, 118, 126, 129, 139, 141, 144, 145,
    172, 173, 180, 181, 182,
    226, 228, 229, 250, 251, 263, 266, 288, 291, 301, 321, 329,
    400, 426,
    800, 801,
    908, 909:
      Result := True;
  else
    Result := False;
  end;
end;

end.
