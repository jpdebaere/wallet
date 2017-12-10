unit UAppParams;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ Copyright (c) 2016 by Albert Molina

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  This unit is a part of Pascal Coin, a P2P crypto currency without need of
  historical operations.

  If you like it, consider a donation using BitCoin:
  16K3HCZRhFUtM8GdWRcfKeaa6KsuyxZaYk

  }

interface

uses
  Classes, IniFiles, UConst, UFolderHelper;

type

  TAddressPort = record
    address : string;
    port : Word;
  end;

  TAppParams = Class(TComponent)
  private
    FIniFile : TIniFile;
    FFileName: AnsiString;
    function GetParam(parameter : AnsiString) : AnsiString;
  public
    Constructor Create(AOwner : TComponent); override;
    Destructor Destroy; override;
    Procedure Clear;
    Procedure Delete(Const ParamName : AnsiString);

    Procedure SetValue(parameter : AnsiString; value : Integer); overload;
    Procedure SetValue(parameter : AnsiString; value : Cardinal); overload;
    Procedure SetValue(parameter : AnsiString; value : AnsiString); overload;
    Procedure SetValue(parameter : AnsiString; value : Int64); overload;
    Procedure SetValue(parameter : AnsiString; value : Boolean); overload;
    procedure SetValue(parameter : AnsiString; value : TAddressPort); overload;
    function IsNil(parameter : AnsiString) : Boolean;
    function GetValue(parameter : AnsiString; const default : AnsiString): AnsiString; overload;
    function GetValue(parameter : AnsiString; const default :  Boolean): Boolean; overload;
    function GetValue(parameter : AnsiString; const default :  Integer): Integer; overload;
    function GetValue(parameter : AnsiString; const default :  Int64): Int64; overload;
    function GetValue(parameter : AnsiString): TAddressPort; overload;

    property FileName : AnsiString read FFileName;
  End;

const
  SectionName = 'GLOBAL';

implementation

uses
  Variants, UAccounts, SysUtils;

procedure TAppParams.Clear;
begin
  FIniFile.EraseSection('');
end;

constructor TAppParams.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FFileName := TFolderHelper.GetPascalCoinDataFolder + PathDelim + CT_SETTINGS_FILENAME;
  FIniFile := TIniFile.Create(FFileName);
  FIniFile.CacheUpdates := False;
end;

procedure TAppParams.Delete(const ParamName: AnsiString);
begin
  FIniFile.DeleteKey(SectionName, ParamName);
end;

destructor TAppParams.Destroy;
begin
  FreeAndNil(FIniFile);
  inherited;
end;

function TAppParams.GetParam(parameter : AnsiString) : AnsiString;
begin
  Result := FIniFile.ReadString(SectionName, parameter, '');
end;

Procedure TAppParams.SetValue(parameter : AnsiString; value : Integer);
begin
  FIniFile.WriteInteger(SectionName, parameter, value);
end;

Procedure TAppParams.SetValue(parameter : AnsiString; value : Cardinal);
begin
  FIniFile.WriteInt64(SectionName, parameter, value);
end;

Procedure TAppParams.SetValue(parameter : AnsiString; value : AnsiString);
begin
  FIniFile.WriteString(SectionName, parameter, value);
end;

Procedure TAppParams.SetValue(parameter : AnsiString; value : Int64);
begin
  FIniFile.WriteInt64(SectionName, parameter, value);
end;

Procedure TAppParams.SetValue(parameter : AnsiString; value : Boolean);
begin
  FIniFile.WriteBool(SectionName, parameter, value);
end;

procedure TAppParams.SetValue(parameter : AnsiString; value : TAddressPort);
begin
  SetValue(parameter, value.address + ':' + IntToStr(value.port));
end;

function TAppParams.IsNil(parameter : AnsiString) : Boolean;
begin
  Result := not FIniFile.ValueExists(SectionName, parameter);
end;

function TAppParams.GetValue(parameter : AnsiString; const default : AnsiString): AnsiString;
begin
  Result := GetEnvironmentVariable(parameter);
  if Result = '' then
  begin
    Result := FIniFile.ReadString(SectionName, parameter, default);
  end;
end;

function TAppParams.GetValue(parameter : AnsiString; const default : Boolean): Boolean;
var
  value : AnsiString;
begin
  value := GetEnvironmentVariable(parameter);
  if value > '' then
  begin
    Result := value[1] = '1';
    exit;
  end;
  Result := FIniFile.ReadBool(SectionName, parameter, default);
end;

function TAppParams.GetValue(parameter : AnsiString; const default : Integer): Integer;
var
  value : AnsiString;
begin
  value := GetEnvironmentVariable(parameter);
  if value > '' then
  begin
    Result := StrToIntDef(value, default);
    exit;
  end;
  Result := FIniFile.ReadInteger(SectionName, parameter, default);
end;

function TAppParams.GetValue(parameter : AnsiString; const default :  Int64): Int64;
var
  value : AnsiString;
begin
  value := GetEnvironmentVariable(parameter);
  if value > '' then
  begin
    Result := StrToInt64Def(value, default);
    exit;
  end;
  Result := FIniFile.ReadInt64(SectionName, parameter, default);
end;

function TAppParams.GetValue(parameter : AnsiString): TAddressPort; overload;
var
  value : AnsiString;
  position : Integer;
begin
  value := GetValue(parameter, '');
  position := Pos(':', value);
  if position < 2 then
  begin
    Result.address := '';
    Result.port := 0;
  end else begin
    Result.address := Copy(value, 1, position - 1);
    Result.port := Word(StrToInt(Copy(value, position + 1)));
  end;
end;

end.
