#Requires AutoHotkey v2.0

; --- CONFIGURAÇÃO ---
CaminhoFFmpeg := "C:\Users\user\Downloads\Conversor_Profissional\ffmpeg-2026-02-04-git-627da1111c-essentials_build\ffmpeg-2026-02-04-git-627da1111c-essentials_build\bin\ffmpeg.exe"
; --------------------

F1:: {
    if !FileExist(CaminhoFFmpeg) {
        MsgBox("FFmpeg não encontrado!")
        return
    }

    if !(PastaOrigem := DirSelect())
        return

    PastaSaida := PastaOrigem "\novos"
    if !DirExist(PastaSaida)
        DirCreate(PastaSaida)

    Arquivos := []
    Loop Files, PastaOrigem "\*.*" {
        ; Adicionado 3gp, wmv, flv, webm, etc. Sinta-se livre para colocar mais extensões separadas por |
        if (A_LoopFileExt ~= "i)^(mp4|mkv|avi|mov|3gp|wmv|flv|webm|m4v)$") {
            ; Separar o nome do arquivo da extensão para podermos salvar como .mp4 depois
            NomeSemExtensao := SubStr(A_LoopFileName, 1, InStr(A_LoopFileName, ".", , -1) - 1)
            Arquivos.Push({Caminho: A_LoopFileFullPath, Nome: A_LoopFileName, NomeSemExt: NomeSemExtensao})
        }
    }

    Total := Arquivos.Length
    if (Total = 0) {
        MsgBox("Nenhum arquivo de vídeo compatível foi encontrado.")
        return
    }

    ; --- Interface ---
    Prog := Gui("+MinSize +AlwaysOnTop", "Conversor Profissional")
    Prog.SetFont("s10", "Segoe UI")
    
    StatusTxt := Prog.Add("Text", "w450 Center", "Iniciando...")
    TempoTxt := Prog.Add("Text", "w450 Center cBlue", "Tempo estimado: Calculando...")
    Barra := Prog.Add("Progress", "w450 h20 cGreen vMinhaBarra Range0-" Total, 0)
    
    Prog.OnEvent("Close", (*) => ExitApp())
    Prog.Show()

    InicioGeral := A_TickCount

    for i, Arq in Arquivos {
        TempoDecorrido := (A_TickCount - InicioGeral) / 1000
        
        ; Cálculo de tempo estimado (ETA)
        if (i > 1) {
            MediaPorArquivo := TempoDecorrido / (i - 1)
            Restantes := Total - (i - 1)
            SegundosRestantes := Round(MediaPorArquivo * Restantes)
            
            Minutos := Floor(SegundosRestantes / 60)
            Segundos := Mod(SegundosRestantes, 60)
            TempoTxt.Value := "Tempo estimado restante: " Minutos "m " Segundos "s"
        }

        StatusTxt.Value := "Processando (" i "/" Total "): " Arq.Nome
        Prog["MinhaBarra"].Value := i - 1
        
        ; ARQUIVO DE SAÍDA: Agora força a extensão a ser .mp4, independente da original
        NomeSaida := Arq.NomeSemExt ".mp4"
        
        ; COMANDO FFmpeg corrigido para salvar com o novo nome
        Comando := '"' CaminhoFFmpeg '" -i "' Arq.Caminho '" -c:v libx264 -crf 22 -preset slow -c:a aac -b:a 128k -y "' PastaSaida '\' NomeSaida '"'
        
        ; Roda escondido e espera terminar
        RunWait(Comando, , "Hide")
    }

    Prog["MinhaBarra"].Value := Total
    TempoTxt.Value := "Concluído em " Round((A_TickCount - InicioGeral) / 1000 / 60, 1) " minutos."
    StatusTxt.Value := "Finalizado!"
    
    SoundBeep(750, 500)
    MsgBox "Sucesso! Todos os arquivos foram convertidos para MP4.", "FFmpeg", "Iconi"
    Prog.Destroy()
}