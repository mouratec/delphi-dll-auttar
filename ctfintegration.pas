unit CtfIntegration;

{$mode delphi}

interface

uses
  SysUtils, Classes, Forms, Math,
  CtfClientLib, CtfEnums, CtfModels, Dialogs, Controls, StdCtrls, CtfLogger;

const
  TAM_BUFFER_PSC = 99000;

type
  TStatusCallback = procedure(const Msg: string) of object;

  TCtfIntegration = class
  private
    FOnStatus: TStatusCallback;
    FInicializada: Boolean;
    FCancelarSolicitado: Boolean;
    FUltimoErroInit: string;
    FCpfCnpjAC: string;
    function Pad(const S: AnsiString; Len: Integer; C: AnsiChar; Left: Boolean): AnsiString;
    function FormatarValor(ValorCentavos: Int64): AnsiString;
    function ApenasDigitos(const S: string): string;
    procedure CopiarParaBuffer(Dest: PAnsiChar; MaxLen: Integer; const Valor: AnsiString);
    procedure LimparBufferPSc(p_sc: PAnsiChar);
    procedure PreencherBufferPSc(p_sc: PAnsiChar; const Valor: AnsiString);
    function LerTextoPSc(p_sc, tam_sc: PAnsiChar): string;
    function MontarDadosIniciais(Request: TTransactionRequest; out Cancelado: Boolean): string;
    function SolicitarDadosAutenticacao801(out Login, Senha, Cnpj: string): Boolean;
    function FormatarComprovante(const TextoBruto: string): string;
    procedure DefinirCancelamento(comando, num_sc, p_sc, tam_sc, aux: PAnsiChar);
  public
    constructor Create;
    property OnStatus: TStatusCallback read FOnStatus write FOnStatus;
    property Inicializada: Boolean read FInicializada;
    property UltimoErroInit: string read FUltimoErroInit;
    property CpfCnpjAC: string read FCpfCnpjAC write FCpfCnpjAC;

    procedure SolicitarCancelamento;
    function DescreverRetornoDLL(const Codigo: string): string;
    function Inicializar: Boolean;
    function ExecutarOperacao(Request: TTransactionRequest): TTransactionResponse;
    function FinalizarTransacao(Response: TTransactionResponse; ConfirmarTransacao: Boolean;
      const DadosAdicionais: string = ''): Boolean;
  end;

implementation

constructor TCtfIntegration.Create;
begin
  inherited Create;
  FInicializada := False;
  FCancelarSolicitado := False;
  FUltimoErroInit := '';
  FCpfCnpjAC := '';
end;

procedure TCtfIntegration.SolicitarCancelamento;
begin
  FCancelarSolicitado := True;
end;

function TCtfIntegration.Pad(const S: AnsiString; Len: Integer; C: AnsiChar; Left: Boolean): AnsiString;
begin
  Result := S;
  while Length(Result) < Len do
    if Left then
      Result := C + Result
    else
      Result := Result + C;
  if Length(Result) > Len then
    Result := Copy(Result, 1, Len);
end;

function TCtfIntegration.FormatarValor(ValorCentavos: Int64): AnsiString;
begin
  if ValorCentavos < 0 then
    ValorCentavos := 0;
  Result := Pad(AnsiString(IntToStr(ValorCentavos)), 12, '0', True);
end;

function TCtfIntegration.ApenasDigitos(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
    if S[i] in ['0'..'9'] then
      Result := Result + S[i];
end;

procedure TCtfIntegration.CopiarParaBuffer(Dest: PAnsiChar; MaxLen: Integer; const Valor: AnsiString);
var
  CopiaLen: Integer;
begin
  FillChar(Dest^, MaxLen + 1, 0);
  CopiaLen := Min(Length(Valor), MaxLen);
  if CopiaLen > 0 then
    Move(Valor[1], Dest^, CopiaLen);
end;

procedure TCtfIntegration.LimparBufferPSc(p_sc: PAnsiChar);
begin
  FillChar(p_sc^, TAM_BUFFER_PSC, Ord(' '));
  p_sc[TAM_BUFFER_PSC] := #0;
end;

procedure TCtfIntegration.PreencherBufferPSc(p_sc: PAnsiChar; const Valor: AnsiString);
var
  CopiaLen: Integer;
begin
  LimparBufferPSc(p_sc);
  CopiaLen := Min(Length(Valor), TAM_BUFFER_PSC);
  if CopiaLen > 0 then
    Move(Valor[1], p_sc^, CopiaLen);
end;

function TCtfIntegration.LerTextoPSc(p_sc, tam_sc: PAnsiChar): string;
var
  iTamSc: Integer;
  iStrLen: Integer;
  sRaw: AnsiString;
begin
  iTamSc := StrToIntDef(Trim(string(StrPas(tam_sc))), 0);
  // Comandos sem retorno textual em p_sc (ex.: 03, 04, 06, 08) devolvem tam_sc='00000';
  // ler StrPas(p_sc) nesses casos retornaria os 99.000 espaços de preenchimento do buffer.
  if iTamSc <= 0 then
    Exit('');

  if iTamSc > TAM_BUFFER_PSC then
    iTamSc := TAM_BUFFER_PSC;

  iStrLen := Integer(StrLen(p_sc));
  if iStrLen < iTamSc then
    iTamSc := iStrLen;

  if iTamSc <= 0 then
    Exit('');

  SetString(sRaw, p_sc, iTamSc);
  Result := string(sRaw);
end;

function TCtfIntegration.FormatarComprovante(const TextoBruto: string): string;
begin
  Result := StringReplace(TextoBruto, '\', sLineBreak, [rfReplaceAll]);
end;

procedure TCtfIntegration.DefinirCancelamento(comando, num_sc, p_sc, tam_sc, aux: PAnsiChar);
begin
  CopiarParaBuffer(comando, 2, CMD_VERIFICAR_CANCELAR); // '08'
  CopiarParaBuffer(num_sc, 4, '0000');
  LimparBufferPSc(p_sc);
  CopiarParaBuffer(tam_sc, 5, '00000');
  CopiarParaBuffer(aux, 1, '0');
end;

function TCtfIntegration.DescreverRetornoDLL(const Codigo: string): string;
var
  Cod: string;
begin
  Cod := Trim(Codigo);
  if Cod = '00' then Result := 'Execução bem-sucedida da função.'
  else if Cod = '02' then Result := 'Erro ao receber a resposta do comando 09.'
  else if Cod = '03' then Result := 'Parâmetro tam_sc inválido do comando 09.'
  else if Cod = '04' then Result := 'Erro nos parâmetros da iniciaTransacaoCTF ou comando da continuaTransacaoCTF.'
  else if Cod = '05' then Result := 'Erro no parâmetro num_sc.'
  else if Cod = '06' then Result := 'Erro no parâmetro p_sc.'
  else if Cod = '07' then Result := 'Erro no parâmetro tam_sc.'
  else if Cod = '08' then Result := 'Erro no parâmetro aux.'
  else if Cod = '09' then Result := 'Parâmetro comando da continuaTransacaoCTF não numérico.'
  else if Cod = '10' then Result := 'Parâmetro comando inválido na continuaTransacaoCTF: deveria ser "00".'
  else if Cod = '11' then Result := 'Parâmetro tam_sc inválido do comando 04 na continuaTransacaoCTF.'
  else if Cod = '12' then Result := 'Parâmetro tam_sc inválido do comando 05 na continuaTransacaoCTF.'
  else if Cod = '13' then Result := 'Parâmetro tam_sc inválido do comando 07 na continuaTransacaoCTF.'
  else if Cod = '14' then Result := 'Parâmetro comando inválido na continuaTransacaoCTF.'
  else if Cod = '15' then Result := 'Comando deveria ser 00 na primeira chamada.'
  else if Cod = '16' then Result := 'Resposta inválida do CTFClient na continuaTransacaoCTF.'
  else if Cod = '17' then Result := 'Erro no parâmetro confirmar da finalizaTransacaoCTF.'
  else if Cod = '18' then Result := 'Erro no parâmetro num_trans da finalizaTransacaoCTF.'
  else if Cod = '19' then Result := 'Erro no parâmetro data_cli da finalizaTransacaoCTF.'
  else if Cod = '20' then Result := 'Parâmetro confirmar inválido (deveria ser 0 ou 1).'
  else if Cod = '21' then Result := 'Parâmetro num_trans inválido na finalizaTransacaoCTF: deveria ser numérico.'
  else if Cod = '22' then Result := 'Parâmetro data_cli inválido na finalizaTransacaoCTF: deveria ser numérico.'
  else if Cod = '23' then Result := 'Algum parâmetro da iniciaClientCTF está com formato inválido.'
  else if Cod = '35' then Result := 'Parâmetro dados inválido.'
  else if Cod = '50' then Result := 'Biblioteca não inicializada na continuaTransacaoCTF.'
  else if Cod = '51' then Result := 'Erro interno na função executada.'
  else if Cod = '52' then Result := 'Erro ao carregar a biblioteca auttar_ctf.'
  else if Cod = '53' then Result := 'Erro ao carregar as bibliotecas de criptografia.'
  else if Cod = '54' then Result := 'Erro ao estabelecer conexão com o CTFClient na iniciaClientCTF.'
  else if Cod = '56' then Result := 'Erro ao receber resposta na finalizaTransacaoCTF.'
  else if Cod = '59' then Result := 'Variável de ambiente CTFCLIENT_HOME não configurada.'
  else if Cod = '60' then Result := 'Porta de conexão com o CTFClient não definida.'
  else if Cod = '61' then Result := 'Erro ao configurar o CTFClient na iniciaClientCTF.'
  else if Cod = '70' then Result := 'Erro ao receber os dados finais da transação.'
  else if Cod = '72' then Result := 'Erro ao receber dados inválidos do CTFClient na finalizaTransacaoCTF.'
  else if Cod = '73' then Result := 'Erro ao receber os dados finais do CTFClient na finalizaTransacaoCTF.'
  else if Cod = '82' then Result := 'Erro ao enviar os dados na finalizaTransacaoCTF.'
  else if Cod = '84' then Result := 'Biblioteca não inicializada na finalizaTransacaoCTF.'
  else if Cod = '85' then Result := 'Biblioteca não inicializada na iniciaTransacaoCTF.'
  else if Cod = '88' then Result := 'Erro ao estabelecer conexão na iniciaTransacaoCTF.'
  else if Cod = '90' then Result := 'Estado da biblioteca incorreto na continuaTransacaoCTF.'
  else if Cod = '92' then Result := 'Não existe conexão estabelecida na continuaTransacaoCTF.'
  else if Cod = '95' then Result := 'Não foi possível iniciar a biblioteca CTFClientC.'
  else Result := 'Código de retorno da DLL: ' + Cod;
end;

function TCtfIntegration.Inicializar: Boolean;
var
  // Nomes idênticos aos parâmetros do Manual v1.83 (iniciaClientCTF)
  resultado: array[0..2] of AnsiChar;
  terminal: array[0..12] of AnsiChar;
  versao: array[0..10] of AnsiChar;
  nome_ac: array[0..20] of AnsiChar;
  num_sites: array[0..2] of AnsiChar;
  lista_ips: array[0..255] of AnsiChar;
  criptografia: array[0..1] of AnsiChar;
  log: array[0..1] of AnsiChar;
  interativo: array[0..1] of AnsiChar;
  parametros: array[0..511] of AnsiChar;
  sParams: AnsiString;
  sRetorno: string;
begin
  FInicializada := False;
  FUltimoErroInit := '';

  if not Assigned(CtfClientLib.iniciaClientCTF) then
  begin
    FUltimoErroInit := 'Biblioteca ctfclient.dll não carregada.';
    Exit(False);
  end;

  // Conforme Manual v1.83: resultado deve ser inicializado com "00"
  CopiarParaBuffer(@resultado[0], 2, '00');
  CopiarParaBuffer(@terminal[0], 12, '000000000000');
  CopiarParaBuffer(@versao[0], 10, Pad('1.0.0', 10, ' ', False));
  CopiarParaBuffer(@nome_ac[0], 20, Pad('MouraPDV', 20, ' ', False));
  CopiarParaBuffer(@num_sites[0], 2, '00');
  CopiarParaBuffer(@lista_ips[0], 255, 'HTTPS');
  CopiarParaBuffer(@criptografia[0], 1, '0');
  CopiarParaBuffer(@log[0], 1, '1');
  CopiarParaBuffer(@interativo[0], 1, '1');

  sParams := 'suporte-https=1';
  if Trim(FCpfCnpjAC) <> '' then
    sParams := sParams + ';cpf-cnpj-ac=' + AnsiString(Pad(AnsiString(Trim(FCpfCnpjAC)), 14, ' ', False));
  CopiarParaBuffer(@parametros[0], 511, '[' + sParams + ']');

  CtfClientLib.iniciaClientCTF(
    @resultado[0],
    @terminal[0],
    @versao[0],
    @nome_ac[0],
    @num_sites[0],
    @lista_ips[0],
    @criptografia[0],
    @log[0],
    @interativo[0],
    @parametros[0]
  );

  sRetorno := Trim(string(StrPas(@resultado[0])));
  FInicializada := (sRetorno = RET_SUCESSO);
  if not FInicializada then
  begin
    FUltimoErroInit := DescreverRetornoDLL(sRetorno) + ' (código: ' + sRetorno + ')';
    LogTEF('ERRO iniciaClientCTF -> resultado:[' + sRetorno + '] ' + FUltimoErroInit);
  end
  else
    LogTEF('iniciaClientCTF OK | terminal:[' + Trim(string(StrPas(@terminal[0]))) + ']');

  Result := FInicializada;
end;

function TCtfIntegration.SolicitarDadosAutenticacao801(out Login, Senha, Cnpj: string): Boolean;
var
  Frm: TForm;
  lblLogin, lblSenha, lblCnpj: TLabel;
  edtLogin, edtSenha, edtCnpj: TEdit;
  btnOk, btnCancel: TButton;
  sCnpjLimpo: string;
  i: Integer;
  Valido: Boolean;
begin
  Result := False;
  Login := '';
  Senha := '';
  Cnpj := '';

  Frm := TForm.CreateNew(nil);
  try
    Frm.Caption := 'TEF Auttar - Autenticação HTTPS (801)';
    Frm.Position := poScreenCenter;
    Frm.BorderStyle := bsDialog;
    Frm.ClientWidth := 380;
    Frm.ClientHeight := 220;
    Frm.Font.Name := 'Segoe UI';
    Frm.Font.Size := 10;

    lblLogin := TLabel.Create(Frm);
    lblLogin.Parent := Frm;
    lblLogin.Caption := 'Login (7917):';
    lblLogin.SetBounds(20, 14, 340, 20);

    edtLogin := TEdit.Create(Frm);
    edtLogin.Parent := Frm;
    edtLogin.SetBounds(20, 34, 340, 25);
    edtLogin.MaxLength := 40;

    lblSenha := TLabel.Create(Frm);
    lblSenha.Parent := Frm;
    lblSenha.Caption := 'Senha (7918):';
    lblSenha.SetBounds(20, 68, 340, 20);

    edtSenha := TEdit.Create(Frm);
    edtSenha.Parent := Frm;
    edtSenha.SetBounds(20, 88, 340, 25);
    edtSenha.MaxLength := 20;
    edtSenha.PasswordChar := '*';

    lblCnpj := TLabel.Create(Frm);
    lblCnpj.Parent := Frm;
    lblCnpj.Caption := 'CNPJ da Loja (7919) (14 caracteres):';
    lblCnpj.SetBounds(20, 122, 340, 20);

    edtCnpj := TEdit.Create(Frm);
    edtCnpj.Parent := Frm;
    edtCnpj.SetBounds(20, 142, 340, 25);
    edtCnpj.MaxLength := 18;

    btnOk := TButton.Create(Frm);
    btnOk.Parent := Frm;
    btnOk.Caption := 'Autenticar';
    btnOk.ModalResult := mrOK;
    btnOk.Default := True;
    btnOk.SetBounds(160, 178, 95, 30);

    btnCancel := TButton.Create(Frm);
    btnCancel.Parent := Frm;
    btnCancel.Caption := 'Cancelar';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Cancel := True;
    btnCancel.SetBounds(265, 178, 95, 30);

    while True do
    begin
      if Frm.ShowModal <> mrOK then
        Exit(False);

      Login := Trim(edtLogin.Text);
      Senha := edtSenha.Text;

      // Remove pontuação comum de CNPJ (., -, /, espaço), mantendo alfanuméricos
      sCnpjLimpo := '';
      for i := 1 to Length(edtCnpj.Text) do
        if edtCnpj.Text[i] in ['0'..'9', 'A'..'Z', 'a'..'z'] then
          sCnpjLimpo := sCnpjLimpo + UpperCase(edtCnpj.Text[i]);

      Valido := (Login <> '') and (Senha <> '') and (Length(sCnpjLimpo) = 14);
      if Valido then
      begin
        Cnpj := sCnpjLimpo;
        Exit(True);
      end;

      MessageDlg('TEF Auttar',
        'Preencha Login, Senha e CNPJ válido (14 caracteres alfanuméricos/dígitos).',
        mtWarning, [mbOK], 0);
    end;
  finally
    Frm.Free;
  end;
end;

function TCtfIntegration.MontarDadosIniciais(Request: TTransactionRequest; out Cancelado: Boolean): string;
var
  sInput, sCartao, sVenc, sDataOrig, sDadosMontados, sLimpo: string;
  QtdParcelas, Dia, Mes: Integer;
begin
  Cancelado := False;
  Result := '';
  sDadosMontados := Trim(Request.dados);
  if sDadosMontados <> '' then
  begin
    if (sDadosMontados[1] <> '[') then
      sDadosMontados := '[' + sDadosMontados + ']';
    Exit(sDadosMontados);
  end;

  case Request.operacao of
    113, 114:
      begin
        sInput := '2';
        while True do
        begin
          if not InputQuery('TEF Auttar', 'Quantidade de Parcelas (2 a 99):', sInput) then
          begin
            Cancelado := True;
            Exit;
          end;
          sLimpo := Trim(sInput);
          if TryStrToInt(sLimpo, QtdParcelas) and (QtdParcelas >= 2) and (QtdParcelas <= 99) and
             (sLimpo = ApenasDigitos(sLimpo)) then
          begin
            sDadosMontados := SC_QTD_PARCELAS + '=' +
              string(Pad(AnsiString(IntToStr(QtdParcelas)), 2, '0', True)) + ';';
            Break;
          end;
          MessageDlg('TEF Auttar', 'Informe uma quantidade inteira de parcelas entre 2 e 99.',
            mtWarning, [mbOK], 0);
        end;
      end;

    120:
      begin
        if Assigned(FOnStatus) then
          FOnStatus('Informe os dados do cartão (ou deixe em branco para captura interativa).');
        sCartao := '';
        while True do
        begin
          if not InputQuery('TEF Auttar', 'Digite o Número do Cartão (7006) (opcional):', sCartao) then
          begin
            Cancelado := True;
            Exit;
          end;
          sLimpo := ApenasDigitos(sCartao);
          if (Trim(sCartao) = '') or ((sLimpo <> '') and (Length(sLimpo) >= 12) and (Length(sLimpo) <= 19)) then
          begin
            sCartao := sLimpo;
            Break;
          end;
          MessageDlg('TEF Auttar', 'Número de cartão inválido (informe entre 12 e 19 dígitos ou deixe em branco).',
            mtWarning, [mbOK], 0);
        end;

        sVenc := '';
        while True do
        begin
          if not InputQuery('TEF Auttar', 'Data de Vencimento (MMAA) (7010) (opcional):', sVenc) then
          begin
            Cancelado := True;
            Exit;
          end;
          sLimpo := ApenasDigitos(sVenc);
          if Trim(sVenc) = '' then
          begin
            sVenc := '';
            Break;
          end;
          if Length(sLimpo) = 4 then
          begin
            Mes := StrToIntDef(Copy(sLimpo, 1, 2), 0);
            if (Mes >= 1) and (Mes <= 12) then
            begin
              sVenc := sLimpo;
              Break;
            end;
          end;
          MessageDlg('TEF Auttar', 'Validade inválida. Informe 4 dígitos no formato MMAA (ex.: 0829) ou deixe em branco.',
            mtWarning, [mbOK], 0);
        end;

        if sCartao <> '' then
          sDadosMontados := sDadosMontados + SC_CARTAO_DIGITADO + '=' + sCartao + ';';
        if sVenc <> '' then
          sDadosMontados := sDadosMontados + SC_DATA_VENCIMENTO + '=' + sVenc + ';';
      end;

    128:
      begin
        if Assigned(FOnStatus) then
          FOnStatus('Dados da Transação Original para Cancelamento.');
        sInput := '';
        while True do
        begin
          if not InputQuery('TEF Auttar', 'NSU CTF Original (7012) (até 6 dígitos; vazio = interativo):', sInput) then
          begin
            Cancelado := True;
            Exit;
          end;
          sLimpo := Trim(sInput);
          if sLimpo = '' then
          begin
            sInput := '';
            Break;
          end;
          if (sLimpo = ApenasDigitos(sLimpo)) and (Length(sLimpo) <= 6) then
          begin
            sInput := sLimpo;
            Break;
          end;
          MessageDlg('TEF Auttar', 'NSU CTF original inválido. Informe somente números (até 6 dígitos).',
            mtWarning, [mbOK], 0);
        end;

        sDataOrig := FormatDateTime('ddmmyy', Now);
        while True do
        begin
          if not InputQuery('TEF Auttar', 'Data da Transação Original (DDMMAA) (7161):', sDataOrig) then
          begin
            Cancelado := True;
            Exit;
          end;
          if Trim(sDataOrig) = '' then
          begin
            sDataOrig := '';
            Break;
          end;
          // Remove barras/espaços caso o operador digite DD/MM/AA
          sLimpo := ApenasDigitos(sDataOrig);
          if Length(sLimpo) = 6 then
          begin
            Dia := StrToIntDef(Copy(sLimpo, 1, 2), 0);
            Mes := StrToIntDef(Copy(sLimpo, 3, 2), 0);
            if (Dia >= 1) and (Dia <= 31) and (Mes >= 1) and (Mes <= 12) then
            begin
              sDataOrig := sLimpo;
              Break;
            end;
          end;
          MessageDlg('TEF Auttar', 'Data inválida. Informe exatamente 6 dígitos no formato DDMMAA (ex.: 121126).',
            mtWarning, [mbOK], 0);
        end;

        if sInput <> '' then
          sDadosMontados := sDadosMontados + SC_NSU_ORIGINAL + '=' +
            string(Pad(AnsiString(sInput), 6, '0', True)) + ';';
        if sDataOrig <> '' then
          sDadosMontados := sDadosMontados + SC_DATA_ORIGINAL + '=' + sDataOrig + ';';
      end;

    423, 431:
      begin
        sInput := '';
        if not InputQuery('TEF Auttar', 'Identificador Pix (7516) (opcional para Consulta):', sInput) then
        begin
          Cancelado := True;
          Exit;
        end;
        if Trim(sInput) <> '' then
          sDadosMontados := sDadosMontados + SC_PIX_ID + '=' + Trim(sInput) + ';';
      end;
  end;

  if sDadosMontados <> '' then
  begin
    if sDadosMontados[Length(sDadosMontados)] = ';' then
      SetLength(sDadosMontados, Length(sDadosMontados) - 1);
    Result := '[' + sDadosMontados + ']';
  end;
end;

function TCtfIntegration.ExecutarOperacao(Request: TTransactionRequest): TTransactionResponse;
var
  Res: TTransactionResponse;
  // Nomes idênticos aos parâmetros do Manual v1.83
  resultado: array[0..16] of AnsiChar;
  operacao: array[0..3] of AnsiChar;
  valor: array[0..12] of AnsiChar;
  num_doc: array[0..20] of AnsiChar;
  data_cli: array[0..8] of AnsiChar;
  num_trans: array[0..2] of AnsiChar;
  dados: array[0..2047] of AnsiChar;
  comando: array[0..16] of AnsiChar;
  num_sc: array[0..16] of AnsiChar;
  tam_sc: array[0..16] of AnsiChar;
  aux: array[0..16] of AnsiChar;
  p_sc: PAnsiChar;

  CmdAtual: Integer;
  sDadosIniciais, sResultado, sComando, sNumSc, sPSc, sAux: string;
  sInput, sMenuTexto, sPrompt, sTituloDialog: string;
  sAuthLogin, sAuthSenha, sAuthCnpj, sRespostaAuto: string;
  sAnsiInput: AnsiString;
  UltimaMensagemDisplay, UltimoTituloMenu: string;
  CanceladoPeloOperador: Boolean;
  MaxDigitos: Integer;
begin
  FCancelarSolicitado := False;
  Res := TTransactionResponse.Create;
  p_sc := nil;
  try
    Res.operacao := Request.operacao;
    Res.num_doc := Request.num_doc;
    if Trim(Request.data_cli) <> '' then
      Res.data_cli := Trim(Request.data_cli)
    else
      Res.data_cli := FormatDateTime('yyyymmdd', Now);

    if Trim(Request.num_trans) <> '' then
      Res.num_trans := string(Pad(AnsiString(Trim(Request.num_trans)), 2, '0', True))
    else
      Res.num_trans := '01';

    if not FInicializada then
    begin
      if not Inicializar then
      begin
        Res.resultado := RET_BIBLIOTECA_NAO_INICIALIZADA_INI;
        Res.mensagem_erro := 'CTFClient não inicializado: ' + FUltimoErroInit;
        Exit(Res);
      end;
    end;

    sAuthLogin := '';
    sAuthSenha := '';
    sAuthCnpj := '';
    if Request.operacao = 801 then
    begin
      if not SolicitarDadosAutenticacao801(sAuthLogin, sAuthSenha, sAuthCnpj) then
      begin
        Res.resultado := 'CANCELADO';
        Res.mensagem_erro := 'Autenticação (801) cancelada pelo operador antes do envio ao TEF.';
        LogTEF('-> Operação 801 cancelada pelo operador antes de iniciar.');
        Exit(Res);
      end;
    end;

    sDadosIniciais := MontarDadosIniciais(Request, CanceladoPeloOperador);
    if CanceladoPeloOperador then
    begin
      Res.resultado := 'CANCELADO';
      Res.mensagem_erro := 'Operação cancelada pelo operador antes do envio ao TEF.';
      LogTEF('-> Operação ' + IntToStr(Request.operacao) + ' cancelada pelo operador antes de iniciar.');
      Exit(Res);
    end;

    if (Request.operacao = 801) and (sDadosIniciais = '') then
      sDadosIniciais := '[7917=' + sAuthLogin + ';7918=' + sAuthSenha + ';7919=' + sAuthCnpj + ']';

    GetMem(p_sc, TAM_BUFFER_PSC + 1);
    try
      CopiarParaBuffer(@resultado[0], 2, '00');
      CopiarParaBuffer(@operacao[0], 3, Pad(AnsiString(IntToStr(Request.operacao)), 3, '0', True));

      if OperacaoSemValor(Request.operacao) then
        CopiarParaBuffer(@valor[0], 12, '000000000000')
      else
        CopiarParaBuffer(@valor[0], 12, FormatarValor(Request.valor_centavos));

      CopiarParaBuffer(@num_doc[0], 20, Pad(AnsiString(Request.num_doc), 20, ' ', False));
      CopiarParaBuffer(@data_cli[0], 8, Pad(AnsiString(Res.data_cli), 8, '0', True));
      CopiarParaBuffer(@num_trans[0], 2, Pad(AnsiString(Res.num_trans), 2, '0', True));
      CopiarParaBuffer(@dados[0], 2047, AnsiString(sDadosIniciais));

      if sDadosIniciais <> '' then
      begin
        if Request.operacao = 801 then
          LogTEF('-> iniciaTransacaoCTFext | op:[' + string(StrPas(@operacao[0])) +
            '] valor:[' + string(StrPas(@valor[0])) + '] dados:[7917=' + sAuthLogin +
            ';7918=***;7919=' + sAuthCnpj + ']')
        else
          LogTEF('-> iniciaTransacaoCTFext | op:[' + string(StrPas(@operacao[0])) +
            '] valor:[' + string(StrPas(@valor[0])) + '] dados:[' + sDadosIniciais + ']');
        CtfClientLib.iniciaTransacaoCTFext(@resultado[0], @operacao[0], @valor[0],
          @num_doc[0], @data_cli[0], @num_trans[0], @dados[0]);
      end
      else
      begin
        LogTEF('-> iniciaTransacaoCTF | op:[' + string(StrPas(@operacao[0])) +
          '] valor:[' + string(StrPas(@valor[0])) + ']');
        CtfClientLib.iniciaTransacaoCTF(@resultado[0], @operacao[0], @valor[0],
          @num_doc[0], @data_cli[0], @num_trans[0]);
      end;

      sResultado := Trim(string(StrPas(@resultado[0])));
      if sResultado <> RET_SUCESSO then
      begin
        Res.resultado := sResultado;
        Res.mensagem_erro := 'Falha ao iniciar transação (' + sResultado + '): ' +
          DescreverRetornoDLL(sResultado);
        LogTEF('<- iniciaTransacaoCTF ERRO | resultado:[' + sResultado + '] ' + Res.mensagem_erro);
        Exit(Res);
      end;

      // Primeira chamada da continuaTransacaoCTF conforme Anexo II
      CopiarParaBuffer(@resultado[0], 2, RET_AGUARDANDO_ACAO);
      CopiarParaBuffer(@comando[0], 2, CMD_RECUPERAR_SUBCAMPO);
      CopiarParaBuffer(@num_sc[0], 4, '0000');
      LimparBufferPSc(p_sc);
      CopiarParaBuffer(@tam_sc[0], 5, '00000');
      CopiarParaBuffer(@aux[0], 1, '0');

      UltimaMensagemDisplay := '';
      UltimoTituloMenu := '';

      while True do
      begin
        Application.ProcessMessages;

        CtfClientLib.continuaTransacaoCTF(@resultado[0], @comando[0], @num_sc[0], p_sc, @tam_sc[0], @aux[0]);

        sResultado := Trim(string(StrPas(@resultado[0])));
        sComando   := Trim(string(StrPas(@comando[0])));
        sNumSc     := Trim(string(StrPas(@num_sc[0])));
        sAux       := Trim(string(StrPas(@aux[0])));
        sPSc       := LerTextoPSc(p_sc, @tam_sc[0]);

        LogTEF('<- continuaTransacaoCTF | resultado:[' + sResultado + '] comando:[' + sComando +
          '] num_sc:[' + sNumSc + '] tam_sc:[' + Trim(string(StrPas(@tam_sc[0]))) +
          '] aux:[' + sAux + '] p_sc:[' + sPSc + ']');

        // Sai imediatamente quando resultado <> '99' (00 = fim normal; outros = erro DLL)
        if sResultado <> RET_AGUARDANDO_ACAO then
          Break;

        CmdAtual := StrToIntDef(sComando, -1);

        case CmdAtual of
          0:
            begin
              // Armazena TODOS os subcampos retornados pela DLL (Anexo III), na ordem recebida
              if (sNumSc <> '') and (sNumSc <> '0000') then
                Res.subcampos.Add(sNumSc + '=' + sPSc);

              if sNumSc = SC_RESULTADO_TRANSACAO then
                Res.codigo_retorno := Trim(sPSc)
              else if sNumSc = SC_VALOR_TRANSACAO then
                Res.valor_final_centavos := StrToInt64Def(Trim(sPSc), 0)
              else if sNumSc = SC_VALOR_DESCONTO then
                Res.desconto_centavos := StrToInt64Def(Trim(sPSc), 0)
              else if sNumSc = SC_CODIGO_RESPOSTA then
                Res.codigo_resposta := Trim(sPSc)
              else if sNumSc = SC_NSU_CTF then
                Res.nsu_ctf := Trim(sPSc)
              else if sNumSc = SC_NSU_AUTORIZADORA then
              begin
                if Res.nsu_autorizadora = '' then
                  Res.nsu_autorizadora := Trim(sPSc);
              end
              else if sNumSc = SC_NSU_AUTORIZADORA_ALFA then
              begin
                if Trim(sPSc) <> '' then
                  Res.nsu_autorizadora := Trim(sPSc);
              end
              else if sNumSc = SC_CODIGO_AUTORIZACAO then
                Res.codigo_autorizacao := Trim(sPSc)
              else if sNumSc = SC_BANDEIRA_CARTAO then
                Res.bandeira := Trim(sPSc)
              else if sNumSc = SC_NOME_TRANSACAO then
                Res.nome_transacao := Trim(sPSc)
              else if sNumSc = SC_MENSAGEM_DISPLAY then
                Res.mensagem_display := Trim(sPSc)
              else if sNumSc = SC_CODIGO_ERRO then
              begin
                if Trim(sPSc) <> '0000' then
                  Res.codigo_erro := Trim(sPSc);
              end
              else if (sNumSc = SC_CUPOM_CLIENTE) or (sNumSc = SC_REIMPRESSAO_CLIENTE) then
                Res.comprovante_cliente.Text := Res.comprovante_cliente.Text + FormatarComprovante(sPSc)
              else if (sNumSc = SC_CUPOM_LOJISTA) or (sNumSc = SC_REIMPRESSAO_LOJISTA) then
                Res.comprovante_lojista.Text := Res.comprovante_lojista.Text + FormatarComprovante(sPSc)
              else if sNumSc = SC_CUPOM_REDUZIDO then
                Res.cupom_reduzido.Text := Res.cupom_reduzido.Text + FormatarComprovante(sPSc)
              else if sNumSc = SC_DADOS_VARIAVEIS then
              begin
                if (Pos('.PNG', UpperCase(sPSc)) > 0) or (Pos('.JPG', UpperCase(sPSc)) > 0) or
                   (Pos('.JPEG', UpperCase(sPSc)) > 0) or (Pos('.BMP', UpperCase(sPSc)) > 0) or
                   (Pos('.GIF', UpperCase(sPSc)) > 0) or FileExists(Trim(sPSc)) then
                begin
                  Res.qr_code_path := Trim(sPSc);
                  if Assigned(FOnStatus) then
                    FOnStatus('QR Code gerado em: ' + Res.qr_code_path);
                end;
              end
              else if sNumSc = SC_ID_CONSULTA then
                Res.id_consulta := Trim(sPSc)
              else if sNumSc = SC_PIX_ID then
                Res.pix_id := Trim(sPSc)
              else if sNumSc = SC_PIX_PSP then
                Res.pix_psp := Trim(sPSc);

              CopiarParaBuffer(@comando[0], 2, CMD_RECUPERAR_SUBCAMPO);
              CopiarParaBuffer(@num_sc[0], 4, '0000');
              LimparBufferPSc(p_sc);
              CopiarParaBuffer(@tam_sc[0], 5, '00000');
              CopiarParaBuffer(@aux[0], 1, '0');
            end;

          1:
            begin
              UltimaMensagemDisplay := StringReplace(sPSc, ';', sLineBreak, [rfReplaceAll]);
              if Assigned(FOnStatus) then
                FOnStatus(StringReplace(sPSc, ';', ' | ', [rfReplaceAll]));

              CopiarParaBuffer(@comando[0], 2, CMD_EXIBIR_MENSAGEM);
              CopiarParaBuffer(@num_sc[0], 4, '0000');
              LimparBufferPSc(p_sc);
              CopiarParaBuffer(@tam_sc[0], 5, '00000');
              CopiarParaBuffer(@aux[0], 1, '0');
            end;

          2:
            begin
              UltimoTituloMenu := StringReplace(sPSc, ';', sLineBreak, [rfReplaceAll]);
              if Assigned(FOnStatus) then
                FOnStatus('[Título] ' + StringReplace(sPSc, ';', ' | ', [rfReplaceAll]));

              CopiarParaBuffer(@comando[0], 2, CMD_EXIBIR_TITULO);
              CopiarParaBuffer(@num_sc[0], 4, '0000');
              LimparBufferPSc(p_sc);
              CopiarParaBuffer(@tam_sc[0], 5, '00000');
              CopiarParaBuffer(@aux[0], 1, '0');
            end;

          3:
            begin
              UltimaMensagemDisplay := '';
              UltimoTituloMenu := '';

              CopiarParaBuffer(@comando[0], 2, CMD_LIMPAR_DISPLAY);
              CopiarParaBuffer(@num_sc[0], 4, '0000');
              LimparBufferPSc(p_sc);
              CopiarParaBuffer(@tam_sc[0], 5, '00000');
              CopiarParaBuffer(@aux[0], 1, '0');
            end;

          4:
            begin
              // Comando 04 não retorna texto próprio; utiliza texto do comando 01/02 anterior
              sPrompt := Trim(UltimaMensagemDisplay);
              if sPrompt = '' then
                sPrompt := Trim(UltimoTituloMenu);
              if sPrompt = '' then
                sPrompt := 'Confirma a operação solicitada pelo TEF?';

              if Assigned(FOnStatus) then
                FOnStatus('Confirmação: ' + sPrompt);

              if MessageDlg('TEF Auttar - Confirmação', sPrompt, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
                sInput := '1'
              else
                sInput := '2';

              CopiarParaBuffer(@comando[0], 2, CMD_OBTER_CONFIRMACAO);
              CopiarParaBuffer(@num_sc[0], 4, '0000');
              PreencherBufferPSc(p_sc, AnsiString(sInput));
              CopiarParaBuffer(@tam_sc[0], 5, '00001');
              CopiarParaBuffer(@aux[0], 1, '0');
            end;

          5:
            begin
              if Assigned(FOnStatus) then
                FOnStatus('Aguardando seleção de opção do menu...');

              sMenuTexto := StringReplace(sPSc, ';', sLineBreak, [rfReplaceAll]);
              sMenuTexto := StringReplace(sMenuTexto, '\', sLineBreak, [rfReplaceAll]);

              if Trim(UltimoTituloMenu) <> '' then
                sTituloDialog := UltimoTituloMenu
              else
                sTituloDialog := 'Menu Auttar';

              sInput := '1';
              if InputQuery(sTituloDialog, sMenuTexto, sInput) and (Trim(sInput) <> '') then
              begin
                sAnsiInput := AnsiString(Trim(sInput));
                CopiarParaBuffer(@comando[0], 2, CMD_EXIBIR_MENU);
                CopiarParaBuffer(@num_sc[0], 4, '0000');
                PreencherBufferPSc(p_sc, sAnsiInput);
                CopiarParaBuffer(@tam_sc[0], 5, Pad(AnsiString(IntToStr(Length(sAnsiInput))), 5, '0', True));
                CopiarParaBuffer(@aux[0], 1, '0');
              end
              else
                DefinirCancelamento(@comando[0], @num_sc[0], p_sc, @tam_sc[0], @aux[0]);
            end;

          6:
            begin
              sPrompt := Trim(UltimaMensagemDisplay);
              if sPrompt = '' then
                sPrompt := Trim(UltimoTituloMenu);
              if sPrompt = '' then
                sPrompt := 'Pressione OK para prosseguir (ou Cancelar para abortar).';

              if Assigned(FOnStatus) then
                FOnStatus('Aguardando confirmação do operador: ' + sPrompt);

              if MessageDlg('TEF Auttar', sPrompt, mtInformation, [mbOK, mbCancel], 0) = mrOK then
              begin
                CopiarParaBuffer(@comando[0], 2, CMD_AGUARDAR_TECLA);
                CopiarParaBuffer(@num_sc[0], 4, '0000');
                LimparBufferPSc(p_sc);
                CopiarParaBuffer(@tam_sc[0], 5, '00000');
                CopiarParaBuffer(@aux[0], 1, '0');
              end
              else
                DefinirCancelamento(@comando[0], @num_sc[0], p_sc, @tam_sc[0], @aux[0]);
            end;

          7:
            begin
              // No comando 07, p_sc traz o tamanho máximo permitido, num_sc o subcampo a capturar,
              // e aux indica se zeros à esquerda são permitidos ('0'=não, '1'=sim).
              MaxDigitos := StrToIntDef(Trim(sPSc), 0);

              // Na operação 801, responde automaticamente 7917/7918/7919 com os dados
              // informados na tela única inicial, sem abrir novos diálogos.
              sRespostaAuto := '';
              if Request.operacao = 801 then
              begin
                if (sNumSc = SC_AUTH_LOGIN) and (sAuthLogin <> '') then
                begin
                  sRespostaAuto := sAuthLogin;
                  sAuthLogin := '';
                end
                else if (sNumSc = SC_AUTH_SENHA) and (sAuthSenha <> '') then
                begin
                  sRespostaAuto := sAuthSenha;
                  sAuthSenha := '';
                end
                else if (sNumSc = SC_AUTH_CNPJ) and (sAuthCnpj <> '') then
                begin
                  sRespostaAuto := sAuthCnpj;
                  sAuthCnpj := '';
                end;
              end;

              if sRespostaAuto <> '' then
              begin
                sAnsiInput := AnsiString(sRespostaAuto);
                if (MaxDigitos > 0) and (Length(sAnsiInput) > MaxDigitos) then
                  sAnsiInput := Copy(sAnsiInput, 1, MaxDigitos);

                if Assigned(FOnStatus) then
                  FOnStatus('Enviando subcampo ' + sNumSc + ' (801)...');

                CopiarParaBuffer(@comando[0], 2, CMD_CAPTURAR_DADO);
                CopiarParaBuffer(@num_sc[0], 4, Pad(AnsiString(sNumSc), 4, '0', True));
                PreencherBufferPSc(p_sc, sAnsiInput);
                CopiarParaBuffer(@tam_sc[0], 5, Pad(AnsiString(IntToStr(Length(sAnsiInput))), 5, '0', True));
                CopiarParaBuffer(@aux[0], 1, '0');
              end
              else
              begin
                sPrompt := Trim(UltimaMensagemDisplay);
              if sPrompt = '' then
                sPrompt := Trim(UltimoTituloMenu);

              if sNumSc = SC_CVV then
                sPrompt := Trim(sPrompt + sLineBreak + 'Digite o código de segurança (CVV):')
              else if sNumSc = SC_DATA_VENCIMENTO then
                sPrompt := Trim(sPrompt + sLineBreak + 'Digite a validade do cartão (MMAA):')
              else if sNumSc = SC_CARTAO_DIGITADO then
                sPrompt := Trim(sPrompt + sLineBreak + 'Digite o número do cartão:')
              else if sNumSc = SC_AUTH_LOGIN then
                sPrompt := Trim(sPrompt + sLineBreak + 'Informe o Login de autenticação:')
              else if sNumSc = SC_AUTH_SENHA then
                sPrompt := Trim(sPrompt + sLineBreak + 'Informe a Senha de autenticação:')
              else if sNumSc = SC_AUTH_CNPJ then
                sPrompt := Trim(sPrompt + sLineBreak + 'Informe o CNPJ da loja:')
              else if sPrompt = '' then
                sPrompt := 'Digite o dado para o subcampo ' + sNumSc + ':';

              if MaxDigitos > 0 then
                sPrompt := sPrompt + Format(' (máx. %d caracteres)', [MaxDigitos]);
              if sAux = '0' then
                sPrompt := sPrompt + ' [sem zeros à esquerda]';

              if Assigned(FOnStatus) then
                FOnStatus('Captura [' + sNumSc + ']: ' + sPrompt);

              sInput := '';
              while True do
              begin
                if not InputQuery('TEF Auttar - Captura (' + sNumSc + ')', sPrompt,
                  (sNumSc = SC_AUTH_SENHA), sInput) then
                begin
                  DefinirCancelamento(@comando[0], @num_sc[0], p_sc, @tam_sc[0], @aux[0]);
                  Break;
                end;

                sAnsiInput := AnsiString(sInput);
                if (MaxDigitos > 0) and (Length(sAnsiInput) > MaxDigitos) then
                begin
                  MessageDlg('TEF Auttar',
                    Format('O dado informado excede o limite de %d caracteres.', [MaxDigitos]),
                    mtWarning, [mbOK], 0);
                  Continue;
                end;

                if (sAux = '0') and (Length(sInput) > 1) and (sInput[1] = '0') then
                begin
                  MessageDlg('TEF Auttar',
                    'Este campo não permite zeros à esquerda (aux=0).',
                    mtWarning, [mbOK], 0);
                  Continue;
                end;

                // Regra obrigatória do Anexo II: devolver exatamente o mesmo num_sc recebido
                CopiarParaBuffer(@comando[0], 2, CMD_CAPTURAR_DADO);
                CopiarParaBuffer(@num_sc[0], 4, Pad(AnsiString(sNumSc), 4, '0', True));
                PreencherBufferPSc(p_sc, sAnsiInput);
                CopiarParaBuffer(@tam_sc[0], 5, Pad(AnsiString(IntToStr(Length(sAnsiInput))), 5, '0', True));
                CopiarParaBuffer(@aux[0], 1, '0');
                Break;
              end;
              end;
            end;

          8:
            begin
              if FCancelarSolicitado then
              begin
                LogTEF('-> Cancelamento solicitado pelo operador durante Cmd 08.');
                DefinirCancelamento(@comando[0], @num_sc[0], p_sc, @tam_sc[0], @aux[0]);
              end
              else
              begin
                CopiarParaBuffer(@comando[0], 2, CMD_RECUPERAR_SUBCAMPO); // '00' para continuar
                CopiarParaBuffer(@num_sc[0], 4, '0000');
                LimparBufferPSc(p_sc);
                CopiarParaBuffer(@tam_sc[0], 5, '00000');
                CopiarParaBuffer(@aux[0], 1, '0');
              end;
            end;

          9:
            begin
              // Menu temporizado conforme Anexo II (1ª execução=menu; '0'=aguarda; '1'=timeout)
              if Trim(sPSc) = '1' then
              begin
                CopiarParaBuffer(@comando[0], 2, CMD_MENU_TEMPORIZADO);
                CopiarParaBuffer(@num_sc[0], 4, '0000');
                LimparBufferPSc(p_sc);
                CopiarParaBuffer(@tam_sc[0], 5, '00000');
                CopiarParaBuffer(@aux[0], 1, '0');
              end
              else if Trim(sPSc) = '0' then
              begin
                if FCancelarSolicitado then
                  DefinirCancelamento(@comando[0], @num_sc[0], p_sc, @tam_sc[0], @aux[0])
                else
                begin
                  CopiarParaBuffer(@comando[0], 2, CMD_MENU_TEMPORIZADO);
                  CopiarParaBuffer(@num_sc[0], 4, '0000');
                  LimparBufferPSc(p_sc);
                  CopiarParaBuffer(@tam_sc[0], 5, '00000');
                  CopiarParaBuffer(@aux[0], 1, '0');
                end;
              end
              else
              begin
                sMenuTexto := StringReplace(sPSc, ';', sLineBreak, [rfReplaceAll]);
                sMenuTexto := StringReplace(sMenuTexto, '\', sLineBreak, [rfReplaceAll]);
                if Trim(UltimoTituloMenu) <> '' then
                  sTituloDialog := UltimoTituloMenu
                else
                  sTituloDialog := 'Menu Auttar (Temporizado)';

                sInput := '1';
                if InputQuery(sTituloDialog, sMenuTexto, sInput) and (Trim(sInput) <> '') then
                begin
                  sAnsiInput := AnsiString(Trim(sInput));
                  CopiarParaBuffer(@comando[0], 2, CMD_MENU_TEMPORIZADO);
                  CopiarParaBuffer(@num_sc[0], 4, '0000');
                  PreencherBufferPSc(p_sc, sAnsiInput);
                  CopiarParaBuffer(@tam_sc[0], 5, Pad(AnsiString(IntToStr(Length(sAnsiInput))), 5, '0', True));
                  CopiarParaBuffer(@aux[0], 1, '1');
                end
                else
                  DefinirCancelamento(@comando[0], @num_sc[0], p_sc, @tam_sc[0], @aux[0]);
              end;
            end;

          else
            begin
              CopiarParaBuffer(@comando[0], 2, CMD_RECUPERAR_SUBCAMPO);
              CopiarParaBuffer(@num_sc[0], 4, '0000');
              LimparBufferPSc(p_sc);
              CopiarParaBuffer(@tam_sc[0], 5, '00000');
              CopiarParaBuffer(@aux[0], 1, '0');
            end;
        end;
      end;

      Res.resultado := sResultado;

      if Res.resultado <> RET_SUCESSO then
      begin
        Res.mensagem_erro := DescreverRetornoDLL(Res.resultado) + ' (DLL: ' + Res.resultado + ')';
      end
      else if not Res.Aprovada then
      begin
        Res.mensagem_erro := Res.mensagem_display;
        if Res.mensagem_erro = '' then
          Res.mensagem_erro := 'Transação não aprovada.';
        if Res.codigo_retorno <> '' then
          Res.mensagem_erro := Res.mensagem_erro + ' [7000=' + Res.codigo_retorno + ']';
        if Res.codigo_erro <> '' then
          Res.mensagem_erro := Res.mensagem_erro + ' [7300=' + Res.codigo_erro + ']';
        if Res.codigo_resposta <> '' then
          Res.mensagem_erro := Res.mensagem_erro + ' [7015=' + Res.codigo_resposta + ']';
      end;

      Result := Res;
    finally
      if p_sc <> nil then
        FreeMem(p_sc, TAM_BUFFER_PSC + 1);
    end;
  except
    Res.Free;
    raise;
  end;
end;

function TCtfIntegration.FinalizarTransacao(Response: TTransactionResponse;
  ConfirmarTransacao: Boolean; const DadosAdicionais: string): Boolean;
var
  // Nomes idênticos aos parâmetros do Manual v1.83 (finalizaTransacaoCTF / ext)
  resultado: array[0..16] of AnsiChar;
  confirmar: array[0..1] of AnsiChar;
  num_trans: array[0..2] of AnsiChar;
  data_cli: array[0..8] of AnsiChar;
  dados: array[0..2047] of AnsiChar;
  sRetorno, sDados: string;
begin
  Result := False;
  if not Assigned(Response) then Exit(False);

  if not OperacaoExigeFinalizacao(Response.operacao) then
  begin
    LogTEF('>>> Operação ' + IntToStr(Response.operacao) + ' não requer finalizaTransacaoCTF.');
    Exit(True);
  end;

  if not Response.Aprovada then
  begin
    LogTEF('>>> finalizaTransacaoCTF ignorada: transação não foi aprovada (7000=' +
      Response.codigo_retorno + ', DLL=' + Response.resultado + ').');
    Exit(False);
  end;

  if (not ConfirmarTransacao) and (not OperacaoPermiteDesfazimento(Response.operacao)) then
  begin
    LogTEF('>>> AVISO: Operação ' + IntToStr(Response.operacao) +
      ' (Pagamento Pix) não permite desfazimento após pagamento.');
    Exit(False);
  end;

  if not Assigned(CtfClientLib.finalizaTransacaoCTF) then Exit(False);

  CopiarParaBuffer(@resultado[0], 2, '00');
  if ConfirmarTransacao then
    CopiarParaBuffer(@confirmar[0], 1, '1')
  else
    CopiarParaBuffer(@confirmar[0], 1, '0');

  CopiarParaBuffer(@num_trans[0], 2, Pad(AnsiString(Response.num_trans), 2, '0', True));
  CopiarParaBuffer(@data_cli[0], 8, Pad(AnsiString(Response.data_cli), 8, '0', True));

  sDados := Trim(DadosAdicionais);
  if sDados <> '' then
  begin
    if sDados[1] <> '[' then
      sDados := '[' + sDados + ']';
    CopiarParaBuffer(@dados[0], 2047, AnsiString(sDados));
    LogTEF('-> finalizaTransacaoCTFext | confirmar:[' + string(StrPas(@confirmar[0])) +
      '] num_trans:[' + string(StrPas(@num_trans[0])) + '] data_cli:[' +
      string(StrPas(@data_cli[0])) + '] dados:[' + sDados + ']');
    CtfClientLib.finalizaTransacaoCTFext(@resultado[0], @confirmar[0], @num_trans[0], @data_cli[0], @dados[0]);
  end
  else
  begin
    LogTEF('-> finalizaTransacaoCTF | confirmar:[' + string(StrPas(@confirmar[0])) +
      '] num_trans:[' + string(StrPas(@num_trans[0])) + '] data_cli:[' +
      string(StrPas(@data_cli[0])) + ']');
    CtfClientLib.finalizaTransacaoCTF(@resultado[0], @confirmar[0], @num_trans[0], @data_cli[0]);
  end;

  sRetorno := Trim(string(StrPas(@resultado[0])));
  Response.resultado_finalizacao := sRetorno;

  Result := (sRetorno = RET_SUCESSO) or (sRetorno = SC7000_MULTITRANSACAO_PENDENTE);
  Response.confirmada := ConfirmarTransacao and Result;

  LogTEF('<- finalizaTransacaoCTF | resultado:[' + sRetorno + '] ok:[' + BoolToStr(Result, True) + ']');
end;

end.
