unit CtfLogger;

{$mode delphi}

interface

uses
  Classes, SysUtils;

procedure LogTEF(const Msg: string);

implementation

var
  GLogStream: TFileStream = nil;
  GLogFalhou: Boolean = False;

function AbrirLog: Boolean;
var
  FileName: string;
begin
  Result := Assigned(GLogStream);
  if Result or GLogFalhou then Exit;
  FileName := ExtractFilePath(ParamStr(0)) + 'CTFDebug.log';
  try
    if FileExists(FileName) then
    begin
      GLogStream := TFileStream.Create(FileName, fmOpenWrite or fmShareDenyNone);
      GLogStream.Seek(0, soEnd);
    end
    else
      GLogStream := TFileStream.Create(FileName, fmCreate or fmShareDenyNone);
    Result := True;
  except
    GLogFalhou := True; // não tenta reabrir a cada linha (evita lentidão)
    GLogStream := nil;
  end;
end;

procedure LogTEF(const Msg: string);
var
  Linha: AnsiString;
begin
  // Arquivo mantido aberto durante toda a execução (evita abrir/fechar a cada subcampo).
  // Falhas de I/O nunca interrompem a transação TEF.
  try
    if not AbrirLog then Exit;
    Linha := AnsiString(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' | ' + Msg + sLineBreak);
    if Length(Linha) > 0 then
      GLogStream.WriteBuffer(Linha[1], Length(Linha));
  except
    // Silencia erro de escrita no log
  end;
end;

finalization
  FreeAndNil(GLogStream);

end.
