program pascalcoin_daemon;

{$mode objfpc}{$H+}
{$define usecthreads}
{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  sysutils,
  Classes, daemonapp,
  UCrypto, upcdaemon, UAccounts, UPoolMining, UAppParams;


begin
  Application.Title:='PascalCoin Daemon application';
  RegisterDaemonClass(TPCDaemon);
  RegisterDaemonMapper(TPCDaemonMapper);
  TCrypto.InitCrypto;
  Application.Run;
end.

