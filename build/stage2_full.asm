; BarsikOS v0.3 - Stage 2 Full System
[BITS 16]
[ORG 0x1000]

%include "boot/stage2.asm"
%include "ui/ui.asm"
%include "installer/installer.asm"
%include "kernel/kernel.asm"
%include "dos/dos.asm"
