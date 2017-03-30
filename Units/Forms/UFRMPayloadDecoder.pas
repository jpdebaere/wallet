unit UFRMPayloadDecoder;

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
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, UBlockChain, UCrypto, UWalletKeys, Buttons, ComCtrls,
  UAppParams;

type

  { TFRMPayloadDecoder }

  TFRMPayloadDecoder = class(TForm)
    Label1: TLabel;
    lblBlock: TLabel;
    lblDateTime: TLabel;
    Label6: TLabel;
    Label2: TLabel;
    lblOperationTxt: TLabel;
    PageControl: TPageControl;
    tsDecoded: TTabSheet;
    tsDecodeMethods: TTabSheet;
    cbMethodPublicPayload: TCheckBox;
    cbUsingPrivateKeys: TCheckBox;
    cbUsingPasswords: TCheckBox;
    memoPasswords: TMemo;
    Label7: TLabel;
    lblDecodedMethod: TLabel;
    Label3: TLabel;
    bbSaveMethods: TBitBtn;
    bbClose: TBitBtn;
    memoDecoded: TMemo;
    memoOriginalPayloadInHexa: TMemo;
    lblPasswordsInfo: TLabel;
    lblAmountCaption: TLabel;
    lblAmount: TLabel;
    lblFeeCaption: TLabel;
    lblFee: TLabel;
    Label4: TLabel;
    bbFind: TBitBtn;
    ebOphash: TEdit;
    lblSenderCaption: TLabel;
    lblSender: TLabel;
    lblReceiverCaption: TLabel;
    lblReceiver: TLabel;
    lblReceiverInfo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure memoOriginalPayloadInHexaChange(Sender: TObject);
    procedure PageControlChanging(Sender: TObject; var AllowChange: Boolean);
    procedure cbMethodPublicPayloadClick(Sender: TObject);
    procedure bbSaveMethodsClick(Sender: TObject);
    procedure memoDecodedKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure bbFindClick(Sender: TObject);
    procedure ebOphashExit(Sender: TObject);
    procedure ebOphashKeyPress(Sender: TObject; var Key: Char);
  private
    FOpResume : TOperationResume;
    FWalletKeys : TWalletKeys;
    FSavedDecodeMethods : boolean;
    FAppParams : TAppParams;
    FSemaphor : Boolean;
    { Private declarations }
    Procedure TryToDecode(payload : TRawBytes);
    Procedure SaveMethods;
    procedure SetOpResume(const Value: TOperationResume);
  public
    { Public declarations }
    Procedure Init(Const AOperationResume : TOperationResume; WalletKeys : TWalletKeys; AppParams : TAppParams);
    Property OpResume : TOperationResume read FOpResume write SetOpResume;
    Procedure DoFind(Const OpHash : String);
  end;

implementation

{$IFnDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$R *.lfm}
{$ENDIF}

Uses UNode, UTime, UECIES, UAES, UAccounts;

{ TFRMPayloadDecoder }

procedure TFRMPayloadDecoder.bbSaveMethodsClick(Sender: TObject);
begin
  SaveMethods;
  PageControl.ActivePage := tsDecoded;
  TryToDecode(FOpResume.OriginalPayload);
end;

procedure TFRMPayloadDecoder.bbFindClick(Sender: TObject);
Var oph : String;
begin
  oph := TCrypto.ToHexaString( FOpResume.OperationHash );
  if Not InputQuery('Search operation by OpHash','Insert Operation Hash value (OpHash)',oph) then exit;
  DoFind(oph);
end;

procedure TFRMPayloadDecoder.cbMethodPublicPayloadClick(Sender: TObject);
begin
  FSavedDecodeMethods := false;
  lblPasswordsInfo.Caption := Format('Possible passwords: %d',[memoPasswords.Lines.Count]);
end;

procedure TFRMPayloadDecoder.DoFind(Const OpHash : String);
Var
  r : TRawBytes;
  pcops : TPCOperationsComp;
  b : Cardinal;
  opbi : Integer;
  opr : TOperationResume;
begin
  // Search for an operation based on "ophash"
  if (trim(OpHash)='') then begin
    OpResume := CT_TOperationResume_NUL;
    exit;
  end;
  try
    r := TCrypto.HexaToRaw(trim(ophash));
    if (r='') then begin
      raise Exception.Create('Value is not an hexadecimal string');
    end;
    pcops := TPCOperationsComp.Create(Nil);
    try
      If not TNode.Node.FindOperation(pcops,r,b,opbi) then begin
        raise Exception.Create('Value is not a valid OpHash');
      end;
      If not TPCOperation.OperationToOperationResume(b,pcops.Operation[opbi],pcops.Operation[opbi].SenderAccount,opr) then begin
        raise Exception.Create('Internal error 20161114-1');
      end;
      opr.NOpInsideBlock:=opbi;
      opr.time:=pcops.OperationBlock.timestamp;
      OpResume := opr;
    finally
      pcops.Free;
    end;
  Except
    OpResume := CT_TOperationResume_NUL;
    try
      FSemaphor := true;
      ebOphash.Text := trim(ophash);
    finally
      FSemaphor := false;
    end;
    Raise;
  end;
end;

procedure TFRMPayloadDecoder.ebOphashExit(Sender: TObject);
begin
  DoFind(ebOphash.Text);
end;

procedure TFRMPayloadDecoder.ebOphashKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then DoFind(ebOphash.Text);
end;

procedure TFRMPayloadDecoder.FormCreate(Sender: TObject);
begin
  FSemaphor := true;
  try
    FWalletKeys := Nil;
    FAppParams := Nil;
    memoDecoded.Lines.Clear;
    memoOriginalPayloadInHexa.Lines.Clear;
    lblPasswordsInfo.Caption := '';
    OpResume := CT_TOperationResume_NUL;
  finally
    FSemaphor := false;
  end;
end;

procedure TFRMPayloadDecoder.memoOriginalPayloadInHexaChange(Sender: TObject);
begin
  TryToDecode(TCrypto.HexaToRaw(memoOriginalPayloadInHexa.Text));
end;

procedure TFRMPayloadDecoder.Init(Const AOperationResume : TOperationResume; WalletKeys : TWalletKeys; AppParams : TAppParams);
begin
  FWalletKeys := WalletKeys;
  FAppParams := AppParams;
  OpResume := AOperationResume;
  FSavedDecodeMethods := true;
  PageControl.ActivePage := tsDecoded;
end;

procedure TFRMPayloadDecoder.memoDecodedKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key=VK_ESCAPE then Close;
end;

procedure TFRMPayloadDecoder.PageControlChanging(Sender: TObject; var AllowChange: Boolean);
begin
  //
  if PageControl.ActivePage=tsDecodeMethods then begin
    If not FSavedDecodeMethods then begin
      case Application.MessageBox(PChar('Save new decode methods?'),PChar(Application.Title),MB_YESNOCANCEL+MB_ICONQUESTION) of
        IDYES : Begin
          SaveMethods;
        End;
        IDCANCEL : begin
          AllowChange := false;
        end;
      end;

    end;
  end else begin
    FSavedDecodeMethods := true;
  end;
end;

procedure TFRMPayloadDecoder.SaveMethods;
begin
  FAppParams.SetValue('PayloadDecoder.notencrypted', cbMethodPublicPayload.Checked);
  FAppParams.SetValue('PayloadDecoder.usingprivatekeys', cbUsingPrivateKeys.Checked);
  FAppParams.SetValue('PayloadDecoder.usingpasswords', cbUsingPasswords.Checked);
  FAppParams.SetValue('PayloadDecoder.passwords', memoPasswords.Lines.Text);
  FSavedDecodeMethods := true;
end;

procedure TFRMPayloadDecoder.SetOpResume(const Value: TOperationResume);
Var sem : Boolean;
begin
  sem := FSemaphor;
  Try
    FSemaphor := false;
    FOpResume := Value;
    if Not Value.valid then begin
      lblBlock.Caption := '';
      lblDateTime.Caption := '';
      lblOperationTxt.Caption := '';
      lblDecodedMethod.Caption := '';
      lblFee.Caption := '';
      lblPasswordsInfo.Caption := '';
      lblAmount.Caption := '';
      lblSender.Caption := '';
      lblReceiver.Caption := '';
      lblReceiverInfo.Visible := false;
      exit;
    end;
    If (Value.NOpInsideBlock>=0) then
      lblBlock.Caption := inttostr(Value.Block)+'/'+inttostr(Value.NOpInsideBlock+1)
    else lblBlock.Caption := inttostr(Value.Block);
    if Value.time>10000 then begin
      lblDateTime.Caption := DateTimeToStr(UnivDateTime2LocalDateTime(UnixToUnivDateTime(Value.time)));
      lblDateTime.Font.Color := clBlack;
    end else begin
      lblDateTime.Caption := '(Pending block)';
      lblDateTime.Font.Color := clRed;
    end;
    lblOperationTxt.Caption := Value.OperationTxt;
    lblAmount.Caption := TAccountComp.FormatMoney(value.Amount);
    if Value.Amount>0 then lblAmount.Font.Color := clGreen
    else if Value.Amount=0 then lblAmount.Font.Color := clGray
    else lblAmount.Font.Color := clRed;
    If (Value.SenderAccount>=0) And (Value.DestAccount>=0) then begin
      lblSenderCaption.Caption := 'Sender:';
      lblSender.Caption := TAccountComp.AccountNumberToAccountTxtNumber(Value.SenderAccount);
      lblReceiverCaption.Visible := true;
      lblReceiver.Caption := TAccountComp.AccountNumberToAccountTxtNumber(Value.DestAccount);
      lblReceiver.Visible := true;
      lblFeeCaption.Visible := Value.AffectedAccount=Value.SenderAccount;
      lblFee.Visible := lblFeeCaption.Visible;
      lblReceiverInfo.Visible := Not lblFee.Visible;
    end else begin
      lblSenderCaption.Caption := 'Account:';
      lblSender.caption := TAccountComp.AccountNumberToAccountTxtNumber(Value.AffectedAccount);
      lblReceiverCaption.Visible := false;
      lblReceiver.Visible := false;
      lblFeeCaption.Visible := true;
      lblFee.Visible := true;
      lblReceiverInfo.Visible := false;
    end;
    lblFee.Caption := TAccountComp.FormatMoney(value.Fee);
    if Value.Fee>0 then lblFee.Font.Color := clGreen
    else if Value.Fee=0 then lblFee.Font.Color := clGray
    else lblFee.Font.Color := clRed;
    ebOpHash.text := TCrypto.ToHexaString(Value.OperationHash);
    memoOriginalPayloadInHexa.Lines.Text := TCrypto.ToHexaString(Value.OriginalPayload);
    if Assigned(FWalletKeys) then begin
      cbMethodPublicPayload.Checked := FAppParams.GetValue('PayloadDecoder.notencrypted', true);
      cbUsingPrivateKeys.Checked := FAppParams.GetValue('PayloadDecoder.usingprivatekeys', true);
      cbUsingPasswords.Checked := FAppParams.GetValue('PayloadDecoder.usingpasswords', true);
      memoPasswords.Lines.Text := FAppParams.GetValue('PayloadDecoder.passwords', '');
    end else begin
      cbMethodPublicPayload.Checked := true;
      cbUsingPrivateKeys.Checked := true;
      cbUsingPasswords.Checked := true;
      memoPasswords.Lines.Text := '';
    end;
    FSavedDecodeMethods := true;
    PageControl.ActivePage := tsDecoded;
    TryToDecode(FOpResume.OriginalPayload);
  Finally
    FSemaphor := sem;
  End;
end;

procedure TFRMPayloadDecoder.TryToDecode(payload : TRawBytes);
  Function UseWallet(Const raw : TRawBytes; var Decrypted : AnsiString; var WalletKey : TWalletKey) : Boolean;
  Var i : Integer;
  begin
    Result := false;
    if Not assigned(FWalletKeys) then exit;

    for i := 0 to FWalletKeys.Count - 1 do begin
      WalletKey := FWalletKeys.Key[i];
      If Assigned(WalletKey.PrivateKey) then begin
        If ECIESDecrypt(WalletKey.PrivateKey.EC_OpenSSL_NID,WalletKey.PrivateKey.PrivateKey,false,raw,Decrypted) then begin
          Result := true;
          exit;
        end;
      end;
    end;

  end;

  Function UsePassword(const raw : TRawBytes; var Decrypted,PasswordUsed : AnsiString) : Boolean;
  Var i : Integer;
  Begin
    Result := false;
    for i := 0 to memoPasswords.Lines.Count - 1 do begin
      if (TAESComp.EVP_Decrypt_AES256(raw,memoPasswords.Lines[i],Decrypted)) then begin
        if (TCrypto.IsHumanReadable(Decrypted)) then begin
          Result := true;
          PasswordUsed := memoPasswords.Lines[i];
          exit;
        end;
      end;
    end;
  End;


var
  WalletKey : TWalletKey;
  Decrypted,PasswordUsed : AnsiString;
  ok : boolean;
begin
  ok := true;
  if Assigned(FWalletKeys) And Assigned(FAppParams) then begin
    if payload <> '' then begin
      if (cbUsingPrivateKeys.Checked) And (UseWallet(payload, Decrypted, WalletKey)) then begin
        memoDecoded.Lines.Text := Decrypted;
        lblDecodedMethod.Caption := 'Encrypted with EC '+TAccountComp.GetECInfoTxt(WalletKey.PrivateKey.EC_OpenSSL_NID);
      end else if (cbMethodPublicPayload.Checked) and (TCrypto.IsHumanReadable(payload)) then begin
        memoDecoded.Lines.Text := payload;
        lblDecodedMethod.Caption := 'Not encrypted payload';
      end else if (cbUsingPasswords.Checked) And (UsePassword(payload, Decrypted, PasswordUsed)) then begin
        memoDecoded.Lines.Text := Decrypted;
        lblDecodedMethod.Caption := 'Encrypted with pwd:"'+PasswordUsed+'"';
      end else begin
        memoDecoded.Lines.Text := 'CANNOT DECRYPT';
        lblDecodedMethod.Caption := '';
        ok := false;
      end;
      if ok then begin
        memoDecoded.Font.Color := clBlack;
        memoDecoded.Color := clWhite;
      end else begin
        memoDecoded.Font.Color := clRed;
        memoDecoded.Color := clBtnFace;
      end;
    end else begin
      memoDecoded.Lines.Text := '(No payload)';
      memoDecoded.Font.Color := clDkGray;
      memoDecoded.Color := clLtGray;
      lblDecodedMethod.Caption := '';
    end;
  end else begin
    memoDecoded.Lines.Text := '';
    lblDecodedMethod.Caption := '';
  end;
end;

end.
