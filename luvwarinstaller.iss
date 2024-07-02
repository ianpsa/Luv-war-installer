[Setup]
AppName=LuV War Modpack Installer
AppVersion=1.0
DefaultDirName={userappdata}\.minecraft\versions\LoVWarModPack
DefaultGroupName=LuV War Modpack
OutputDir=.
OutputBaseFilename=LuVWarModpackInstaller
AllowNoIcons=yes
DisableProgramGroupPage=yes
SetupIconFile=.\icon.ico

[Files]
; Copia o instalador do Forge
Source: ".\forge-installer.jar"; DestDir: "{userappdata}\.minecraft\versions\LoVWarModPack"; Flags: ignoreversion

; Copia os arquivos de mods, configuração e outros para a pasta de destino
Source: ".\mods\*"; DestDir: "{userappdata}\.minecraft\versions\LoVWarModPack\mods"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".\config\*"; DestDir: "{userappdata}\.minecraft\versions\LoVWarModPack\config"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".\servers.dat"; DestDir: "{userappdata}\.minecraft\versions\LoVWarModPack"; Flags: ignoreversion
Source: ".\LuVWarModpack.json"; DestDir: "{userappdata}\.minecraft\versions\LoVWarModPack"; Flags: ignoreversion

[Tasks]
Name: "selectminecraft"; Description: "Minecraft Original"; GroupDescription: "Selecione o launcher de Minecraft"; Flags: exclusive unchecked
Name: "selecttlauncher"; Description: "TLauncher (Pirata)"; GroupDescription: "Selecione o launcher de Minecraft"; Flags: exclusive unchecked

[Run]
; As condições para executar o launcher selecionado serão definidas no código
Filename: "{code:GetLauncherExe}"; Flags: postinstall runhidden

[Code]
function GetJavaPath(Param: String): String;
var
  JavaPath: String;
begin
  // Tenta encontrar o Java no registro do Windows
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\JavaSoft\Java Runtime Environment\1.8', 'JavaHome', JavaPath) or
     RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\JavaSoft\Java Development Kit\1.8', 'JavaHome', JavaPath) or
     RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\JavaSoft\Java Runtime Environment\17', 'JavaHome', JavaPath) or
     RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\JavaSoft\Java Development Kit\17', 'JavaHome', JavaPath) then
  begin
    Result := AddBackslash(JavaPath) + 'bin\java.exe';
    if FileExists(Result) then Exit;
  end;
  
  // Tenta encontrar o Java na variável de ambiente JAVA_HOME
  JavaPath := GetEnv('JAVA_HOME');
  if JavaPath <> '' then
  begin
    Result := AddBackslash(JavaPath) + 'bin\java.exe';
    if FileExists(Result) then Exit;
  end;

  // Tenta encontrar o Java executando diretamente o comando 'java'
  if FileSearch('java.exe', GetEnv('PATH')) <> '' then
  begin
    Result := 'java';
    Exit;
  end;

  // Se nenhum Java for encontrado, exibe uma mensagem de erro
  MsgBox('Java não foi encontrado no sistema. Por favor, instale o Java e tente novamente.', mbError, MB_OK);
  Result := '';
end;

function GetJavaParameters(Param: String): String;
begin
  Result := '-jar ' + ExpandConstant('{userappdata}\.minecraft\versions\LoVWarModPack\forge-installer.jar') + ' --installClient';
end;

function SaveStringToFile(const FileName: string; const S: string): Boolean;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := S;
    SL.SaveToFile(FileName);
    Result := True;
  finally
    SL.Free;
  end;
end;

procedure ExecuteForgeInstaller;
var
  ResultCode: Integer;
  MinecraftPath, JarPath, VersionPath: String;
begin
  MinecraftPath := ExpandConstant('{userappdata}\.minecraft\versions\LoVWarModPack\');
  
  // Verifica e cria a pasta de perfis do Minecraft se necessário
  if not DirExists(MinecraftPath) then
  begin
    if not CreateDir(MinecraftPath) then
    begin
      MsgBox('Não foi possível criar a pasta do Minecraft: ' + MinecraftPath, mbError, MB_OK);
      Exit;
    end;
  end;

  // Copia o perfil do Minecraft para a pasta de destino
  if not FileExists(MinecraftPath + '\launcher_profiles.json') then
  begin
    SaveStringToFile(MinecraftPath + '\launcher_profiles.json', '{"profiles": {}}');
  end;

  // Abre o instalador do Forge
  if Exec(GetJavaPath(''), GetJavaParameters(''), MinecraftPath, SW_SHOW, ewWaitUntilTerminated, ResultCode) then
  begin
    if ResultCode = 0 then
    begin
      MsgBox('A instalação do Forge foi concluída com sucesso!', mbInformation, MB_OK);

      // Caminhos para manipulação de arquivos
      JarPath := ExpandConstant('{userappdata}\.minecraft\versions\LoVWarModPack\versions\1.19.2\1.19.2.jar');      
      // Verifica se o arquivo .jar existe no local esperado
      if FileExists(JarPath) then
      begin
        // Renomeia e move o arquivo .jar
        if not RenameFile(JarPath, MinecraftPath + 'LoVWarModpack.jar') then
        begin
          MsgBox('Não foi possível mover o arquivo 1.19.2.jar para a pasta LoVWarModPack.', mbError, MB_OK);
          Exit;
        end;
      end
      else
      begin
        MsgBox('Não foi possível encontrar o arquivo 1.19.2.jar na pasta ' + ExtractFilePath(JarPath), mbError, MB_OK);
        Exit;
      end;

      // Remove a pasta criada pelo Forge
      if not RemoveDir(ExtractFilePath(JarPath)) then
      begin
        MsgBox('Não foi possível remover a pasta ' + ExtractFilePath(JarPath), mbError, MB_OK);
      end;

      // Mensagem de conclusão
      MsgBox('Instalação finalizada com sucesso! se estiver utilizando tlauncher, abra o launcher, clique em tlmods e clique em criar um pacote com minecraft na versão 1.19.2 e nomeie o pacote lovwarmodpack', mbInformation, MB_OK);
    end
    else
    begin
      MsgBox('A instalação do Forge falhou com o código de erro: ' + IntToStr(ResultCode), mbError, MB_OK);
    end;
  end
  else
  begin
    MsgBox('Não foi possível executar o instalador do Forge.', mbError, MB_OK);
  end;
end;

function GetLauncherExe(Param: String): String;
begin
  if IsTaskSelected('selectminecraft') then
    Result := ExpandConstant('{userappdata}\.minecraft\minecraft.exe')
  else if IsTaskSelected('selecttlauncher') then
    Result := ExpandConstant('{userappdata}\.minecraft\TLauncher.exe')
  else
    Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    ExecuteForgeInstaller;
  end;
end;

[Icons]
Name: "{group}\Desinstalar LuV War Modpack"; Filename: "{uninstallexe}"
