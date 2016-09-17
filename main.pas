unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public
    FFiles: TStringList;
    FRJavaFiles: TStringList;
    FResourceIDs: TStringList;
    procedure ListFiles();
    procedure FindRDotJavaFiles();
    procedure ProcessRDotJavaFiles();
    procedure ReplaceResources();
    //function ProcessLine(ALine: string): string;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.FormShow(Sender: TObject);
begin
  FFiles := TStringList.Create;
  FRJavaFiles := TStringList.Create;
  FResourceIDs := TStringList.Create;
  ListFiles();
  FindRDotJavaFiles();
  ProcessRDotJavaFiles();
  ReplaceResources();
  FFiles.Free;
  FRJavaFiles.Free;
  FResourceIDs.Free;
end;

procedure TForm1.ListFiles;
begin
  Memo1.Lines.Add('Creating files list');
  FindAllFiles(FFiles, './TestFiles', '*.*');
  Memo1.Lines.Add('OK');
end;

procedure TForm1.FindRDotJavaFiles;
var
  I: integer;
begin
  Memo1.Lines.Add('Search for R.java files');
  I := 0;
  while (I < FFiles.Count) do
  begin
    if (LowerCase(ExtractFileName(FFiles[I])) = 'r.java') then
    begin
      FRJavaFiles.Add(FFiles[I]);
      FFiles.Delete(I);
      Dec(I);
      Memo1.Lines.Add('Found : ' + FFiles[I]);
    end;
    Inc(I);
  end;
  Memo1.Lines.Add('OK');
end;

procedure TForm1.ProcessRDotJavaFiles;
var
  TmpStr, clazz, AName: string;
  FileLoader: TStringList;
  I, J: integer;
  K: SizeInt;
begin
  Memo1.Lines.Add('Processing R.java files');
  FileLoader := TStringList.Create;
  FResourceIDs.NameValueSeparator := '=';
  for I := 0 to FRJavaFiles.Count - 1 do
  begin
    FileLoader.LoadFromFile(FRJavaFiles[I]);
    for J := 0 to FileLoader.Count - 1 do
    begin
      TmpStr := FileLoader[J];
      K := Pos(' final ', TmpStr);
      if (K <= 0) then
        Continue;
      Delete(TmpStr, 1, K + 6);
      if (Pos('class', TmpStr) = 1) then
      begin
        Delete(TmpStr, 1, 6);
        clazz := TmpStr;
      end
      else if (Pos('int', TmpStr) = 1) then
      begin
        TmpStr := Copy(TmpStr, 4, Length(TmpStr) - 4);
        if (TmpStr[1] = '[') then // Remove Array
          Delete(TmpStr, 1, 2);
        TmpStr := StringReplace(TmpStr, ' ', '', [rfIgnoreCase, rfReplaceAll]);
        K := Pos('=', TmpStr);
        AName := Copy(TmpStr, 1, K - 1);
        TmpStr := Copy(TmpStr, K + 1, Length(TmpStr) - K);
        if (TmpStr[1] <> '{') then
        begin
          FResourceIDs.Add(TmpStr + '=' + 'R.' + clazz + '.' + AName);
          WriteLn(TmpStr + '=' + 'R.' + clazz + '.' + AName);
        end
        else
        begin
          Delete(TmpStr, 1, 1);
          Delete(TmpStr, Length(TmpStr), 1);
          while (Length(TmpStr) > 0) do
          begin
            K := Pos(',', TmpStr);
            if (K < 1) then
            begin
              FResourceIDs.Add(TmpStr + '=' + 'R.' + clazz + '.' + AName);
              TmpStr := '';
            end
            else
            begin
              FResourceIDs.Add(Copy(TmpStr, 1, K - 1) + '=' + 'R.' + clazz + '.' + AName);
              Delete(TmpStr, 1, K);
              WriteLn('R.' + clazz + '.' + AName + '=' + Copy(TmpStr, 1, K - 1));
            end;
          end;
        end;
      end;
    end;
  end;
  FileLoader.Free;
  Memo1.Lines.Add('OK');
end;

procedure TForm1.ReplaceResources;
var
  I, J: integer;
  AStream: TFileStream;
  AStr: string;
begin
  Memo1.Lines.Add('Processing java files');
  for I := 0 to FFiles.Count - 1 do
  begin
    Application.ProcessMessages;
    AStream := TFileStream.Create(FFiles[I], fmOpenRead);
    SetLength(AStr, AStream.Size);
    AStream.Position := 0;
    AStream.Read(AStr[1], AStream.Size);
    AStream.Free;
    for J := 0 to FResourceIDs.Count - 1 do
    begin
      AStr := StringReplace(AStr, FResourceIDs.Names[J], FResourceIDs.ValueFromIndex[J], [rfReplaceAll]);
    end;
    AStream := TFileStream.Create(FFiles[I], fmCreate);
    AStream.Write(AStr[1], Length(AStr));
    AStream.Free;
    Memo1.Lines.Add('[OK] ' + FFiles[I]);
  end;
  Memo1.Lines.Add('OK');
end;

end.
