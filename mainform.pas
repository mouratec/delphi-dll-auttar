unit MainForm;

{******************************************************************************
  Projeto: Delphi PDV Auttar TEF
  Desenvolvedor: Gabriel Moura
  Data de Criação: 25/04/2026
  Descrição: Módulo de integração de alto nível com a DLL CTFClient da Auttar para x86.
******************************************************************************}
{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, Dialogs,
  CtfIntegration, CtfModels, CtfClientLib, CtfEnums;

type
  TForm1 = class(TForm)
  private
    FTef: TCtfIntegration;

    // Componentes da Interface
    pnlHeader: TPanel;
    pnlActions: TPanel;
    pnlLog: TPanel;
    lblTitulo: TLabel;
    lblStatusHeader: TLabel;

    // Inputs e Labels
    edtValor: TEdit;
    lblValor: TLabel;
    edtDocumento: TEdit;
    lblDoc: TLabel;
    memLog: TMemo;

    // Lista de Botões
    btnValidar: TButton;
    btnCancelarOp: TButton;
    btnDebito, btnCredito, btnParcelado, btnDigitado, btnPix,
    btnConsultaPix, btnDevolucaoPix, btnCancelamento, btnConfig, btnReimpressao, btnAuth: TButton;

    procedure CriarBotao(var Btn: TButton; Caption: string; TopPos: Integer; TagOp: Integer);
    procedure SetBotoesOperacaoEnabled(Habilitar: Boolean);
    procedure SetInterfaceBusy(Busy: Boolean);
    procedure AtualizarStatusTEF(const Msg: string);
    procedure ExibirSubcampos(Resp: TTransactionResponse);
    function CriarJanelaQrCode(const CaminhoImagem: string; ValorCentavos: Int64): TForm;
    procedure ExecutarAcaoTEF(Sender: TObject);
    procedure btnValidarClick(Sender: TObject);
    procedure btnCancelarOpClick(Sender: TObject);

    function GerarDOCPorData: string;
    function TryConverterValorParaCentavos(const Texto: string; out Centavos: Int64): Boolean;
    procedure ValidarConexaoTEF;
    procedure FormShow(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

implementation

constructor TForm1.Create(TheOwner: TComponent);
begin
  inherited CreateNew(TheOwner, 1);

  FTef := TCtfIntegration.Create;
  FTef.OnStatus := AtualizarStatusTEF;

  // Configurações da Janela Principal
  Self.Caption := 'Delphi PDV Auttar TEF';
  Self.SetBounds(0, 0, 1000, 790);
  Self.Position := poScreenCenter;
  Self.Color := $00F0F0F0;
  Self.Font.Name := 'Segoe UI';
  Self.Font.Size := 10;
  Self.OnShow := FormShow;

  // --- HEADER (CABEÇALHO) ---
  pnlHeader := TPanel.Create(Self);
  pnlHeader.Parent := Self;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 85;
  pnlHeader.Color := $002D2D2D;
  pnlHeader.BevelOuter := bvNone;

  lblTitulo := TLabel.Create(pnlHeader);
  lblTitulo.Parent := pnlHeader;
  lblTitulo.Align := alTop;
  lblTitulo.Alignment := taCenter;
  lblTitulo.Caption := 'DELPHI PDV AUTTAR TEF';
  lblTitulo.Font.Color := clWhite;
  lblTitulo.Font.Style := [fsBold];
  lblTitulo.Font.Size := 16;
  lblTitulo.Top := 15;

  lblStatusHeader := TLabel.Create(pnlHeader);
  lblStatusHeader.Parent := pnlHeader;
  lblStatusHeader.Align := alBottom;
  lblStatusHeader.Alignment := taCenter;
  lblStatusHeader.Caption := 'Aguardando Validação...';
  lblStatusHeader.Font.Color := $004080FF;
  lblStatusHeader.Font.Style := [fsBold];
  lblStatusHeader.Font.Size := 11;
  lblStatusHeader.Height := 35;
  lblStatusHeader.Layout := tlCenter;

  // --- PAINEL LATERAL (AÇÕES E INPUTS) ---
  pnlActions := TPanel.Create(Self);
  pnlActions.Parent := Self;
  pnlActions.Align := alLeft;
  pnlActions.Width := 280;
  pnlActions.BevelOuter := bvNone;
  pnlActions.Color := clWhite;

  // 1. Botão de Reconectar no topo das ações
  btnValidar := TButton.Create(pnlActions);
  btnValidar.Parent := pnlActions;
  btnValidar.SetBounds(20, 20, 240, 45);
  btnValidar.Caption := 'Reconectar CTFClient';
  btnValidar.Font.Style := [fsBold];
  btnValidar.OnClick := btnValidarClick;

  // 2. Inputs de Valor e Documento
  lblValor := TLabel.Create(pnlActions);
  lblValor.Parent := pnlActions;
  lblValor.Caption := 'Valor da Transação (R$):';
  lblValor.Top := 85;
  lblValor.Left := 20;

  edtValor := TEdit.Create(pnlActions);
  edtValor.Parent := pnlActions;
  edtValor.SetBounds(20, 105, 240, 30);
  edtValor.Text := '7,77';
  edtValor.Font.Size := 14;
  edtValor.Font.Style := [fsBold];
  edtValor.Alignment := taRightJustify;

  lblDoc := TLabel.Create(pnlActions);
  lblDoc.Parent := pnlActions;
  lblDoc.Caption := 'Documento da Automação:';
  lblDoc.Top := 150;
  lblDoc.Left := 20;

  edtDocumento := TEdit.Create(pnlActions);
  edtDocumento.Parent := pnlActions;
  edtDocumento.SetBounds(20, 170, 240, 25);
  edtDocumento.ReadOnly := True;
  edtDocumento.Color := $00EEEEEE;
  edtDocumento.Alignment := taCenter;

  // 3. Botões de Operação
  CriarBotao(btnDebito,       '101 - DÉBITO À VISTA',     215, 101);
  CriarBotao(btnCredito,      '112 - CRÉDITO À VISTA',    254, 112);
  CriarBotao(btnParcelado,    '113 - CRÉDITO PARCELADO',  293, 113);
  CriarBotao(btnDigitado,     '120 - CRÉDITO DIGITADO',   332, 120);
  CriarBotao(btnPix,          '422 - PAGAMENTO PIX',      371, 422);
  CriarBotao(btnConsultaPix,  '423 - CONSULTA PIX',       410, 423);
  CriarBotao(btnDevolucaoPix, '431 - DEVOLUÇÃO PIX',      449, 431);
  CriarBotao(btnCancelamento, '128 - CANCELAMENTO',       488, 128);
  CriarBotao(btnReimpressao,  '012 - REIMPRESSÃO',        527,  12);
  CriarBotao(btnConfig,       '800 - CONFIGURAÇÃO',       566, 800);
  CriarBotao(btnAuth,         '801 - AUTENTICAÇÃO HTTPS', 605, 801);

  // 4. Botão para cancelar operação interativa em curso (Comando 08)
  btnCancelarOp := TButton.Create(pnlActions);
  btnCancelarOp.Parent := pnlActions;
  btnCancelarOp.SetBounds(20, 650, 240, 34);
  btnCancelarOp.Caption := 'Cancelar Operação em Curso';
  btnCancelarOp.Enabled := False;
  btnCancelarOp.OnClick := btnCancelarOpClick;

  // --- ÁREA DE LOG E COMPROVANTES ---
  pnlLog := TPanel.Create(Self);
  pnlLog.Parent := Self;
  pnlLog.Align := alClient;
  pnlLog.BevelOuter := bvNone;
  pnlLog.BorderWidth := 15;

  memLog := TMemo.Create(pnlLog);
  memLog.Parent := pnlLog;
  memLog.Align := alClient;
  memLog.ReadOnly := True;
  memLog.Color := $00FAFAFA;
  memLog.Font.Name := 'Consolas';
  memLog.Font.Size := 10;
  memLog.ScrollBars := ssVertical;
  memLog.Lines.Add('>>> PDV Inicializado. Aguarde validação...');
end;

destructor TForm1.Destroy;
begin
  FTef.Free;
  inherited Destroy;
end;

procedure TForm1.CriarBotao(var Btn: TButton; Caption: string; TopPos: Integer; TagOp: Integer);
begin
  Btn := TButton.Create(pnlActions);
  Btn.Parent := pnlActions;
  Btn.SetBounds(20, TopPos, 240, 33);
  Btn.Caption := Caption;
  Btn.Tag := TagOp;
  Btn.OnClick := ExecutarAcaoTEF;
  Btn.Enabled := False;
  Btn.Cursor := crHandPoint;
end;

procedure TForm1.SetBotoesOperacaoEnabled(Habilitar: Boolean);
begin
  btnDebito.Enabled := Habilitar;
  btnCredito.Enabled := Habilitar;
  btnParcelado.Enabled := Habilitar;
  btnDigitado.Enabled := Habilitar;
  btnPix.Enabled := Habilitar;
  btnConsultaPix.Enabled := Habilitar;
  btnDevolucaoPix.Enabled := Habilitar;
  btnCancelamento.Enabled := Habilitar;
  btnReimpressao.Enabled := Habilitar;
  btnConfig.Enabled := Habilitar;
  btnAuth.Enabled := Habilitar;
end;

procedure TForm1.SetInterfaceBusy(Busy: Boolean);
begin
  btnValidar.Enabled := not Busy;
  edtValor.Enabled := not Busy;
  SetBotoesOperacaoEnabled((not Busy) and FTef.Inicializada);
  btnCancelarOp.Enabled := Busy;
end;

function TForm1.GerarDOCPorData: string;
begin
  Result := FormatDateTime('ddmmyyyyhhnnss', Now);
end;

function TForm1.TryConverterValorParaCentavos(const Texto: string; out Centavos: Int64): Boolean;
var
  S, IntPartStr, FracPartStr, DigitosLimpos: string;
  PosSep, i: Integer;
  IntVal, FracVal: Int64;
begin
  Result := False;
  Centavos := 0;

  S := Trim(Texto);
  S := StringReplace(S, 'R$', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, ' ', '', [rfReplaceAll]);
  if S = '' then Exit;

  // Localiza o último separador decimal (vírgula ou ponto)
  PosSep := 0;
  for i := Length(S) downto 1 do
    if (S[i] = ',') or (S[i] = '.') then
    begin
      PosSep := i;
      Break;
    end;

  if (PosSep > 0) and ((Length(S) - PosSep) in [1, 2]) then
  begin
    IntPartStr := Copy(S, 1, PosSep - 1);
    FracPartStr := Copy(S, PosSep + 1, 2);
    while Length(FracPartStr) < 2 do
      FracPartStr := FracPartStr + '0';
  end
  else
  begin
    IntPartStr := S;
    FracPartStr := '00';
  end;

  DigitosLimpos := '';
  for i := 1 to Length(IntPartStr) do
  begin
    if IntPartStr[i] in ['0'..'9'] then
      DigitosLimpos := DigitosLimpos + IntPartStr[i]
    else if not (IntPartStr[i] in ['.', ',']) then
      Exit(False);
  end;

  if DigitosLimpos = '' then
    DigitosLimpos := '0';

  for i := 1 to Length(FracPartStr) do
    if not (FracPartStr[i] in ['0'..'9']) then
      Exit(False);

  if not TryStrToInt64(DigitosLimpos, IntVal) then Exit(False);
  if not TryStrToInt64(FracPartStr, FracVal) then Exit(False);

  Centavos := (IntVal * 100) + FracVal;
  Result := True;
end;

procedure TForm1.ValidarConexaoTEF;
begin
  lblStatusHeader.Caption := 'Verificando Serviço Auttar CTFClient...';
  lblStatusHeader.Font.Color := clYellow;
  Application.ProcessMessages;

  if not LoadCTFLibrary then
  begin
    lblStatusHeader.Caption := 'ERRO: DLL da Auttar não encontrada.';
    lblStatusHeader.Font.Color := $006666FF;
    memLog.Lines.Add('CRÍTICO: ' + CTFLastLoadError);
    SetBotoesOperacaoEnabled(False);
    Exit;
  end;

  if FTef.Inicializar then
  begin
    lblStatusHeader.Caption := '[OK] TEF Auttar Conectado. PDV Pronto para Vendas.';
    lblStatusHeader.Font.Color := $0040FF40;
    SetBotoesOperacaoEnabled(True);
    memLog.Lines.Add('>>> Módulo TEF Validado com Sucesso (' + CTFDllPathCarregada + ').');
    //edtDocumento.Text := GerarDOCPorData;
  end
  else
  begin
    lblStatusHeader.Caption := '[ERRO] CTFClient Offline ou Falha na Inicialização.';
    lblStatusHeader.Font.Color := $006666FF;
    SetBotoesOperacaoEnabled(False);
    memLog.Lines.Add('ERRO: ' + FTef.UltimoErroInit);
    memLog.Lines.Add('Verifique se o CTFClient Auttar está aberto e clique em "Reconectar CTFClient".');
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  ValidarConexaoTEF;
end;

procedure TForm1.btnValidarClick(Sender: TObject);
begin
  memLog.Lines.Clear;
  memLog.Lines.Add('>>> Forçando reconexão manual com o TEF...');
  ValidarConexaoTEF;
end;

procedure TForm1.btnCancelarOpClick(Sender: TObject);
begin
  FTef.SolicitarCancelamento;
  memLog.Lines.Add('>>> Solicitação de cancelamento enviada...');
end;

procedure TForm1.AtualizarStatusTEF(const Msg: string);
begin
  // Sem Length(memLog.Text) (O(n) a cada linha) e sem ProcessMessages extra:
  // o loop da continuaTransacaoCTF já processa mensagens a cada iteração.
  memLog.Lines.Add('> ' + Msg);
  memLog.SelStart := MaxInt;
end;

procedure TForm1.ExibirSubcampos(Resp: TTransactionResponse);
var
  i, p: Integer;
  sNum, sValor: string;
begin
  if (Resp = nil) or (Resp.subcampos.Count = 0) then Exit;

  memLog.Lines.BeginUpdate;
  try
    memLog.Lines.Add('');
    memLog.Lines.Add('==================== SUBCAMPOS RETORNADOS PELA DLL (' +
      IntToStr(Resp.subcampos.Count) + ') ====================');
    for i := 0 to Resp.subcampos.Count - 1 do
    begin
      p := Pos('=', Resp.subcampos[i]);
      sNum := Copy(Resp.subcampos[i], 1, p - 1);
      sValor := Copy(Resp.subcampos[i], p + 1, MaxInt);
      // Comprovantes já foram exibidos acima por completo; aqui mostra só o resumo
      if (sNum = SC_CUPOM_CLIENTE) or (sNum = SC_CUPOM_LOJISTA) or
         (sNum = SC_REIMPRESSAO_CLIENTE) or (sNum = SC_REIMPRESSAO_LOJISTA) or
         (sNum = SC_CUPOM_REDUZIDO) then
        sValor := Format('<comprovante: %d caracteres, exibido acima>', [Length(sValor)]);
      memLog.Lines.Add(Format('%-4s | %-32s | %s', [sNum, NomeSubcampo(sNum), sValor]));
    end;
    memLog.Lines.Add('=====================================================================');
  finally
    memLog.Lines.EndUpdate;
  end;
  memLog.SelStart := MaxInt;
end;

function TForm1.CriarJanelaQrCode(const CaminhoImagem: string; ValorCentavos: Int64): TForm;
var
  lblInfo, lblValor: TLabel;
  imgQr: TImage;
begin
  Result := TForm.CreateNew(nil, 1);
  Result.Caption := 'Pagamento PIX - Escaneie o QR Code';
  Result.SetBounds(0, 0, 360, 400);
  Result.Position := poScreenCenter;
  Result.BorderStyle := bsDialog;
  Result.FormStyle := fsStayOnTop;
  Result.Color := clWhite;

  lblInfo := TLabel.Create(Result);
  lblInfo.Parent := Result;
  lblInfo.Align := alTop;
  lblInfo.Alignment := taCenter;
  lblInfo.WordWrap := True;
  lblInfo.Caption := 'Escaneie o QR Code abaixo ou no Pinpad';
  lblInfo.Font.Name := 'Segoe UI';
  lblInfo.Font.Size := 11;
  lblInfo.Font.Style := [fsBold];
  lblInfo.BorderSpacing.Top := 12;
  lblInfo.BorderSpacing.Left := 12;
  lblInfo.BorderSpacing.Right := 12;

  lblValor := TLabel.Create(Result);
  lblValor.Parent := Result;
  lblValor.Align := alTop;
  lblValor.Alignment := taCenter;
  lblValor.Caption := Format('Valor: R$ %.2f', [ValorCentavos / 100.0]);
  lblValor.Font.Name := 'Segoe UI';
  lblValor.Font.Size := 12;
  lblValor.Font.Color := $00804000;
  lblValor.Font.Style := [fsBold];
  lblValor.BorderSpacing.Top := 4;
  lblValor.BorderSpacing.Bottom := 8;

  imgQr := TImage.Create(Result);
  imgQr.Parent := Result;
  imgQr.Align := alClient;
  imgQr.Center := True;
  imgQr.Proportional := True;
  imgQr.Stretch := True;
  imgQr.BorderSpacing.Around := 12;
  try
    imgQr.Picture.LoadFromFile(CaminhoImagem);
  except
    Result.Free;
    raise;
  end;
end;

procedure TForm1.ExecutarAcaoTEF(Sender: TObject);
var
  Req: TTransactionRequest;
  Resp, RespConsulta: TTransactionResponse;
  frmQrCode: TForm;
  OpSelecionada: Integer;
  NomeOp: string;
  ValorCentavos, ValorFinalCentavos: Int64;
  ImpressaoOK, DeveConfirmar, Finalizou: Boolean;
begin
  OpSelecionada := TButton(Sender).Tag;
  NomeOp := TButton(Sender).Caption;

  ValorCentavos := 0;
  if not OperacaoSemValor(OpSelecionada) then
  begin
    if not TryConverterValorParaCentavos(edtValor.Text, ValorCentavos) or (ValorCentavos <= 0) then
    begin
      ShowMessage('Informe um valor válido maior que zero para a transação.');
      edtValor.SetFocus;
      Exit;
    end;
  end;

  if not LoadCTFLibrary then
  begin
    ShowMessage(CTFLastLoadError);
    Exit;
  end;

  if not FTef.Inicializada then
  begin
    ValidarConexaoTEF;
    if not FTef.Inicializada then Exit;
  end;

  edtDocumento.Text := GerarDOCPorData;
  memLog.Lines.Clear;
  memLog.Lines.Add('----------------------------------------');
  memLog.Lines.Add(' OPERAÇÃO: ' + NomeOp);
  memLog.Lines.Add('----------------------------------------');
  memLog.Lines.Add('DOC Base : ' + edtDocumento.Text);
  if ValorCentavos > 0 then
    memLog.Lines.Add(Format('Valor    : R$ %.2f (%d centavos)', [ValorCentavos / 100.0, ValorCentavos]));
  memLog.Lines.Add('');

  SetInterfaceBusy(True);
  Req := TTransactionRequest.Create;
  Resp := nil;
  RespConsulta := nil;
  frmQrCode := nil;
  try
    Req.operacao := OpSelecionada;
    Req.valor_centavos := ValorCentavos;
    Req.num_doc := edtDocumento.Text;
    Req.data_cli := FormatDateTime('yyyymmdd', Now);
    Req.num_trans := '01';

    if OpSelecionada = StrToInt(OP_PIX_PAGAMENTO) then
    begin
      // Fluxo Anexo VIII (422 - Pagamento Pix com consulta):
      // 1a chamada com 7391=1 gera a imagem do QR Code (7029) e o ID da consulta (7390);
      // 2a chamada com 7390=<id> exibe no Pinpad enquanto a tela exibe a imagem do 7029.
      Req.dados := '[' + SC_FLAG_CONSULTA + '=1]';
      RespConsulta := FTef.ExecutarOperacao(Req);

      if Assigned(RespConsulta) and RespConsulta.Aprovada and
         (RespConsulta.id_consulta <> '') and
         (RespConsulta.id_consulta <> StringOfChar('0', Length(RespConsulta.id_consulta))) then
      begin
        memLog.Lines.Add('QR Code PIX gerado (7390): ' + RespConsulta.id_consulta);
        if RespConsulta.qr_code_path <> '' then
          memLog.Lines.Add('Arquivo QR Code (7029): ' + RespConsulta.qr_code_path);

        if (RespConsulta.qr_code_path <> '') and FileExists(RespConsulta.qr_code_path) then
        begin
          try
            frmQrCode := CriarJanelaQrCode(RespConsulta.qr_code_path, ValorCentavos);
            frmQrCode.Show;
            Application.ProcessMessages;
          except
            on E: Exception do
              memLog.Lines.Add('Aviso: não foi possível abrir imagem QR Code (' + E.Message + ').');
          end;
        end;

        Req.dados := '[' + SC_ID_CONSULTA + '=' + RespConsulta.id_consulta + ']';
        try
          Resp := FTef.ExecutarOperacao(Req);
        finally
          FreeAndNil(frmQrCode);
        end;
        FreeAndNil(RespConsulta);
      end
      else
      begin
        Resp := RespConsulta;
        RespConsulta := nil;
      end;
    end
    else
      Resp := FTef.ExecutarOperacao(Req);

    if Assigned(Resp) and Resp.Aprovada then
    begin
      ImpressaoOK := True;
      try
        if Resp.comprovante_cliente.Text <> '' then
        begin
          memLog.Lines.Add('');
          memLog.Lines.Add('... [ VIA DO CLIENTE ] .................');
          memLog.Lines.Add(Resp.comprovante_cliente.Text);
          memLog.Lines.Add('........................................');
        end;

        if Resp.comprovante_lojista.Text <> '' then
        begin
          memLog.Lines.Add('');
          memLog.Lines.Add('... [ VIA DO ESTABELECIMENTO ] .........');
          memLog.Lines.Add(Resp.comprovante_lojista.Text);
          memLog.Lines.Add('........................................');
        end;

        if Resp.cupom_reduzido.Text <> '' then
        begin
          memLog.Lines.Add('');
          memLog.Lines.Add('... [ CUPOM REDUZIDO (7384) ] ..........');
          memLog.Lines.Add(Resp.cupom_reduzido.Text);
          memLog.Lines.Add('........................................');
        end;

        if Resp.qr_code_path <> '' then
        begin
          memLog.Lines.Add('');
          memLog.Lines.Add('QR Code (7029): ' + Resp.qr_code_path);
        end;
      except
        on E: Exception do
        begin
          ImpressaoOK := False;
          memLog.Lines.Add('ERRO NA IMPRESSÃO/EXIBIÇÃO DO COMPROVANTE: ' + E.Message);
        end;
      end;

      if OperacaoExigeFinalizacao(OpSelecionada) then
      begin
        // Conforme Manual v1.83 (fluxo-uso-biblioteca.png): comprovante impresso com sucesso ->
        // confirmar='1'; falha na impressão -> desfazer com confirmar='0'
        // (exceto 422 Pix, que não permite desfazimento). Sem diálogo extra para agilizar o fluxo.
        if OperacaoPermiteDesfazimento(OpSelecionada) then
          DeveConfirmar := ImpressaoOK
        else
          DeveConfirmar := True;

        Finalizou := FTef.FinalizarTransacao(Resp, DeveConfirmar);

        if Resp.valor_final_centavos > 0 then
          ValorFinalCentavos := Resp.valor_final_centavos
        else
          ValorFinalCentavos := ValorCentavos;

        if DeveConfirmar and Finalizou then
        begin
          memLog.Lines.Add('');
          memLog.Lines.Add('+--------------------------------------+');
          memLog.Lines.Add('|   TRANSAÇÃO APROVADA E CONFIRMADA    |');
          memLog.Lines.Add('+--------------------------------------+');
          memLog.Lines.Add(Format('| NSU CTF   : %-24s |', [Resp.nsu_ctf]));
          if Resp.nsu_autorizadora <> '' then
            memLog.Lines.Add(Format('| NSU AUT.  : %-24s |', [Resp.nsu_autorizadora]));
          memLog.Lines.Add(Format('| AUT       : %-24s |', [Resp.codigo_autorizacao]));
          if Resp.bandeira <> '' then
            memLog.Lines.Add(Format('| BANDEIRA  : %-24s |', [Resp.bandeira]));
          if Resp.nome_transacao <> '' then
            memLog.Lines.Add(Format('| OPERAÇÃO  : %-24s |', [Resp.nome_transacao]));
          if Resp.pix_id <> '' then
            memLog.Lines.Add(Format('| PIX ID    : %-24s |', [Resp.pix_id]));
          if Resp.pix_psp <> '' then
            memLog.Lines.Add(Format('| PIX PSP   : %-24s |', [Resp.pix_psp]));
          if (Resp.id_consulta <> '') and
             (Resp.id_consulta <> StringOfChar('0', Length(Resp.id_consulta))) then
            memLog.Lines.Add(Format('| CONSULTA  : %-24s |', [Resp.id_consulta]));
          memLog.Lines.Add(Format('| DOCUMENTO : %-24s |', [edtDocumento.Text]));
          if Resp.desconto_centavos > 0 then
            memLog.Lines.Add(Format('| DESCONTO  : R$ %-21.2f |', [Resp.desconto_centavos / 100.0]));
          memLog.Lines.Add(Format('| VALOR     : R$ %-21.2f |', [ValorFinalCentavos / 100.0]));
          memLog.Lines.Add(Format('| FINALIZ.  : %-24s |', [Resp.resultado_finalizacao]));
          memLog.Lines.Add('+--------------------------------------+');
        end
        else if (not DeveConfirmar) and Finalizou then
        begin
          ShowMessage('TRANSAÇÃO DESFEITA (confirmar=0)!' + sLineBreak +
                      'NSU CTF original: ' + Resp.nsu_ctf);
          memLog.Lines.Add('');
          memLog.Lines.Add('+--------------------------------------+');
          memLog.Lines.Add('|  TRANSAÇÃO DESFEITA (confirmar = 0)  |');
          memLog.Lines.Add('+--------------------------------------+');
          memLog.Lines.Add(Format('| NSU CTF   : %-24s |', [Resp.nsu_ctf]));
          memLog.Lines.Add(Format('| FINALIZ.  : %-24s |', [Resp.resultado_finalizacao]));
          memLog.Lines.Add('+--------------------------------------+');
        end
        else
        begin
          ShowMessage('ATENÇÃO: Transação aprovada pelo host (NSU ' + Resp.nsu_ctf +
                      '), mas falhou na finalizaTransacaoCTF (retorno = ' +
                      Resp.resultado_finalizacao + ').');
          memLog.Lines.Add('');
          memLog.Lines.Add('ERRO NA FINALIZAÇÃO: finalizaTransacaoCTF retornou [' +
            Resp.resultado_finalizacao + ']');
        end;
      end
      else
      begin
        memLog.Lines.Add('');
        memLog.Lines.Add('+--------------------------------------+');
        memLog.Lines.Add('|         OPERAÇÃO CONCLUÍDA           |');
        memLog.Lines.Add('+--------------------------------------+');
        if Resp.mensagem_display <> '' then
          memLog.Lines.Add('Mensagem       : ' + Resp.mensagem_display);
        if Resp.nsu_ctf <> '' then
          memLog.Lines.Add('NSU CTF (7031) : ' + Resp.nsu_ctf);
        if Resp.nsu_autorizadora <> '' then
          memLog.Lines.Add('NSU Aut.       : ' + Resp.nsu_autorizadora);
        if Resp.codigo_autorizacao <> '' then
          memLog.Lines.Add('Autoriz. (7564): ' + Resp.codigo_autorizacao);
        if Resp.pix_id <> '' then
          memLog.Lines.Add('Pix ID (7516)  : ' + Resp.pix_id);
        if Resp.id_consulta <> '' then
          memLog.Lines.Add('Consulta (7390): ' + Resp.id_consulta);
      end;
    end
    else
    begin
      memLog.Lines.Add('');
      memLog.Lines.Add('----------------------------------------');
      memLog.Lines.Add('[ERRO] STATUS: NEGADO / CANCELADO / FALHA');
      if Assigned(Resp) then
      begin
        memLog.Lines.Add('DLL (resultado) : ' + Resp.resultado);
        if Resp.codigo_retorno <> '' then
          memLog.Lines.Add('Subcampo 7000   : ' + Resp.codigo_retorno);
        if Resp.codigo_resposta <> '' then
          memLog.Lines.Add('Subcampo 7015   : ' + Resp.codigo_resposta);
        if Resp.codigo_erro <> '' then
          memLog.Lines.Add('Subcampo 7300   : ' + Resp.codigo_erro);
        if Resp.mensagem_display <> '' then
          memLog.Lines.Add('Display (7385)  : ' + Resp.mensagem_display);
        memLog.Lines.Add('Detalhe         : ' + Resp.mensagem_erro);
      end;
      memLog.Lines.Add('----------------------------------------');
    end;

    // Exibe ao final TODOS os subcampos retornados pela DLL (aprovada, negada ou consulta)
    ExibirSubcampos(Resp);
  finally
    FreeAndNil(frmQrCode);
    FreeAndNil(RespConsulta);
    Req.Free;
    if Assigned(Resp) then Resp.Free;
    SetInterfaceBusy(False);
  end;
end;

end.
