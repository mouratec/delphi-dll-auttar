program AuttarTefProject;

{$mode delphi}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // Framework do Lazarus (Obrigatório ser um dos primeiros)
  Forms,      // Gestão da Aplicação
  SysUtils,   // Utilitários de Sistema
  MainForm,   // Unit da interface principal
  CtfClientLib,
  CtfLogger;

{$R *.res}

begin
  Application.Title := 'AuttarTef';
  Application.Scaled := True;
  Application.Initialize;

  try
    Application.CreateForm(TForm1, Form1);
    Application.Run;
  except
    on E: Exception do
    begin
      if Form1 <> nil then
        Form1.Free;
      Writeln('Erro Fatal na Inicialização: ' + E.Message);
    end;
  end;
end.
