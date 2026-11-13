unit CtfModels;

{$mode delphi}

interface

uses Classes, SysUtils;

type
  TTransactionRequest = class
  public
    operacao: Integer;
    valor_centavos: Int64;
    num_doc: string;
    data_cli: string;
    num_trans: string;
    dados: string;
    terminal: string;
    constructor Create;
  end;

  TTransactionResponse = class
  public
    operacao: Integer;
    data_cli: string;
    num_trans: string;
    num_doc: string;
    resultado: string;             // Retorno da DLL ('00' = função concluída)
    codigo_retorno: string;        // Subcampo 7000 ('00' = transação aprovada)
    codigo_resposta: string;       // Subcampo 7015 (código resposta autorizadora)
    codigo_erro: string;           // Subcampo 7300 (código erro quando <> '0000')
    valor_final_centavos: Int64;   // Subcampo 7005 (valor final retornado, ex.: com desconto)
    desconto_centavos: Int64;      // Subcampo 7387 (valor do desconto monetário)
    nsu_ctf: string;               // Subcampo 7031
    nsu_autorizadora: string;      // Subcampos 7081 / 7381
    codigo_autorizacao: string;    // Subcampo 7564
    bandeira: string;              // Subcampo 7389
    nome_transacao: string;        // Subcampo 7948
    mensagem_display: string;      // Subcampo 7385
    mensagem_erro: string;
    qr_code_path: string;          // Subcampo 7029 (caminho da imagem QR Pix)
    id_consulta: string;           // Subcampo 7390 (Identificador da consulta)
    pix_id: string;                // Subcampo 7516
    pix_psp: string;               // Subcampo 7517
    comprovante_cliente: TStringList; // Subcampos 7302 / 7304
    comprovante_lojista: TStringList; // Subcampos 7303 / 7305
    cupom_reduzido: TStringList;   // Subcampo 7384
    subcampos: TStringList;        // Todos os subcampos retornados no comando 00 (num_sc=p_sc)
    resultado_finalizacao: string; // Retorno da finalizaTransacaoCTF
    confirmada: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Aprovada: Boolean;
  end;

implementation

constructor TTransactionRequest.Create;
begin
  inherited Create;
  operacao := 0;
  valor_centavos := 0;
  num_doc := '';
  data_cli := FormatDateTime('yyyymmdd', Now);
  num_trans := '01';
  dados := '';
  terminal := '000000000000';
end;

constructor TTransactionResponse.Create;
begin
  inherited Create;
  comprovante_cliente := TStringList.Create;
  comprovante_lojista := TStringList.Create;
  cupom_reduzido := TStringList.Create;
  subcampos := TStringList.Create;
  valor_final_centavos := 0;
  desconto_centavos := 0;
  num_trans := '01';
  confirmada := False;
end;

destructor TTransactionResponse.Destroy;
begin
  comprovante_cliente.Free;
  comprovante_lojista.Free;
  cupom_reduzido.Free;
  subcampos.Free;
  inherited Destroy;
end;

function TTransactionResponse.Aprovada: Boolean;
begin
  if Trim(resultado) <> '00' then
    Exit(False);

  // Conforme Manual v1.83 e Manual de Códigos de Erro v1.05:
  // Subcampo 7000 = '00' (ou '13' em multitransação) indica aprovação da rotina.
  Result := (Trim(codigo_retorno) = '00') or (Trim(codigo_retorno) = '13');

  // Para Consulta Pix (423) e Devolução Pix (431), o manual define que 7000='00'
  // confirma o processamento da consulta/requisição, e 7015='00' indica autorização.
  if Result and ((operacao = 423) or (operacao = 431)) and (Trim(codigo_resposta) <> '') then
    Result := (Trim(codigo_resposta) = '00');
end;

end.
