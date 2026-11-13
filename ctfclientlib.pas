unit CtfClientLib;

{$mode delphi}

interface

uses Windows, SysUtils;

const
  // Caminho padrão conforme instalação oficial Auttar
  CTF_DLL_PADRAO_X86 = 'C:\Program Files (x86)\Auttar\CTFClient\bin\ctfclient.dll';
  CTF_DLL_PADRAO_X64 = 'C:\Program Files\Auttar\CTFClient\bin\ctfclient.dll';

type
  // Definições com PAnsiChar e stdcall conforme Manual de Integração v1.83
  // utilizando exatamente os nomes de parâmetros da documentação.
  TIniciaClientCTF = procedure(
    resultado, terminal, versao, nome_ac, num_sites,
    lista_ips, criptografia, log, interativo, parametros: PAnsiChar
  ); stdcall;

  TIniciaTransacaoCTF = procedure(
    resultado, operacao, valor, num_doc, data_cli, num_trans: PAnsiChar
  ); stdcall;

  TIniciaTransacaoCTFext = procedure(
    resultado, operacao, valor, num_doc, data_cli, num_trans, dados: PAnsiChar
  ); stdcall;

  TContinuaTransacaoCTF = procedure(
    resultado, comando, num_sc, p_sc, tam_sc, aux: PAnsiChar
  ); stdcall;

  TFinalizaTransacaoCTF = procedure(
    resultado, confirmar, num_trans, data_cli: PAnsiChar
  ); stdcall;

  TFinalizaTransacaoCTFext = procedure(
    resultado, confirmar, num_trans, data_cli, dados: PAnsiChar
  ); stdcall;

var
  iniciaClientCTF: TIniciaClientCTF;
  iniciaTransacaoCTF: TIniciaTransacaoCTF;
  iniciaTransacaoCTFext: TIniciaTransacaoCTFext;
  continuaTransacaoCTF: TContinuaTransacaoCTF;
  finalizaTransacaoCTF: TFinalizaTransacaoCTF;
  finalizaTransacaoCTFext: TFinalizaTransacaoCTFext;
  hDLL: THandle;
  CTFLastLoadError: string;
  CTFDllPathCarregada: string;

function ResolveCTFClientDllPath: string;
function LoadCTFLibrary: Boolean;
procedure UnloadCTFLibrary;

implementation

function ResolveCTFClientDllPath: string;
var
  CtfHome: string;
  Candidato: string;
begin
  CtfHome := Trim(GetEnvironmentVariable('CTFCLIENT_HOME'));
  if CtfHome <> '' then
  begin
    Candidato := IncludeTrailingPathDelimiter(CtfHome) + 'bin\ctfclient.dll';
    if FileExists(Candidato) then Exit(Candidato);

    Candidato := IncludeTrailingPathDelimiter(CtfHome) + 'ctfclient.dll';
    if FileExists(Candidato) then Exit(Candidato);
  end;

  Candidato := ExtractFilePath(ParamStr(0)) + 'ctfclient.dll';
  if FileExists(Candidato) then Exit(Candidato);

  if FileExists(CTF_DLL_PADRAO_X86) then Exit(CTF_DLL_PADRAO_X86);
  if FileExists(CTF_DLL_PADRAO_X64) then Exit(CTF_DLL_PADRAO_X64);

  Result := CTF_DLL_PADRAO_X86;
end;

procedure UnloadCTFLibrary;
begin
  if hDLL <> 0 then
  begin
    FreeLibrary(hDLL);
    hDLL := 0;
  end;
  iniciaClientCTF := nil;
  iniciaTransacaoCTF := nil;
  iniciaTransacaoCTFext := nil;
  continuaTransacaoCTF := nil;
  finalizaTransacaoCTF := nil;
  finalizaTransacaoCTFext := nil;
  CTFDllPathCarregada := '';
end;

function LoadCTFLibrary: Boolean;
var
  DllPath: string;
begin
  Result := False;
  CTFLastLoadError := '';

  if hDLL <> 0 then Exit(True);

  DllPath := ResolveCTFClientDllPath;
  hDLL := LoadLibraryA(PAnsiChar(AnsiString(DllPath)));
  if hDLL = 0 then
  begin
    CTFLastLoadError := 'Não foi possível carregar a DLL em: ' + DllPath +
      ' (Erro Windows: ' + IntToStr(GetLastError) + ')';
    Exit;
  end;

  // Nomes de busca (GetProcAddress) exatos conforme Manual v1.83
  iniciaClientCTF         := GetProcAddress(hDLL, 'iniciaClientCTF');
  iniciaTransacaoCTF      := GetProcAddress(hDLL, 'iniciaTransacaoCTF');
  iniciaTransacaoCTFext   := GetProcAddress(hDLL, 'iniciaTransacaoCTFext');
  continuaTransacaoCTF    := GetProcAddress(hDLL, 'continuaTransacaoCTF');
  finalizaTransacaoCTF    := GetProcAddress(hDLL, 'finalizaTransacaoCTF');
  finalizaTransacaoCTFext := GetProcAddress(hDLL, 'finalizaTransacaoCTFext');

  if not Assigned(iniciaClientCTF) or
     not Assigned(iniciaTransacaoCTF) or
     not Assigned(iniciaTransacaoCTFext) or
     not Assigned(continuaTransacaoCTF) or
     not Assigned(finalizaTransacaoCTF) or
     not Assigned(finalizaTransacaoCTFext) then
  begin
    CTFLastLoadError := 'Uma ou mais funções obrigatórias não foram encontradas na ctfclient.dll.';
    UnloadCTFLibrary;
    Exit;
  end;

  CTFDllPathCarregada := DllPath;
  Result := True;
end;

initialization
  hDLL := 0;
  CTFLastLoadError := '';
  CTFDllPathCarregada := '';

finalization
  UnloadCTFLibrary;

end.
