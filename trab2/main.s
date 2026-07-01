.equ SYS_READ,   0
.equ SYS_WRITE,  1
.equ SYS_EXIT,   60
.equ STDIN,      0
.equ STDOUT,     1

.section .rodata
#verificar
msg_entrada:       .string "Digite a expressão (ex: f(x)=x+3 ou f(5)): "
msg_entrada_l = . - msg_entrada

msg_cont:         .string "Continuar? (s/n): "
msg_cont_l = . - msg_cont

msg_res:          .string "Resultado: "
msg_res_l = . - msg_res

msg_nl:           .string "\n"
msg_nl_l = . - msg_nl

msg_ponto:        .string "."
msg_sinal_menos:  .ascii "-"

.align 8
const_dez:        .double 10.0
const_um: .double 1.0

.section .bss
.global buf_entrada
.global funcoes
.global buf_op1
.global buf_op2
.global operador

buf_entrada: .space 64 # linha digitada pelo usuário
buf_out: .space 64 # buffer de saída
funcoes: .space 520 # vetor de funções (26 * 20 bytes)
buf_op1: .space 64 # buffer do operando 1
buf_op2: .space 64 # buffer do operando 2
operador: .space 4  # buffer do operador

.section .text
.global _start
.global ler_operando
.global converter_para_float
.global imprimir_string
.global exibir_resultado

_start:
    call loop_principal

    movq $SYS_EXIT, %rax
    movq $0,        %rdi
    syscall

loop_principal:
    pushq %rbp
    movq  %rsp, %rbp

.Lloop:
    # imprimir msg entrada
    movq $msg_entrada, %rsi
    movq $msg_entrada_l, %rdx
    call imprimir_string

    #lendo teclado
    movq $buf_entrada, %rsi
    movq $64, %rdx
    call ler_teclado

    # busca o '=' na linha
    movq $buf_entrada, %rsi

.Landa_string:
    movb (%rsi), %al
    cmpb $0, %al 
    je .Lchamada #e o fim da string, e nao tem o =

    cmpb $10, %al 
    je .Lchamada # deu \n e nao tem =

    cmpb $'=', %al
    je .Ldefinicao # acho o igual

    incq %rsi
    jmp .Landa_string #nao foi o fim e nao tem =,ai a gnt anda um p direita

.Ldefinicao:
    call salvar_funcao
    #aqui a gnt tem q salva funcao
    jmp .Lperguntar_cont

.Lchamada:
    call preparar_chamada
    #aqui a gnt extrai os dados do vetor e preenche os buffers
    call executar_operacao

    cmpq $1, %rax
    je .Lperguntar_cont #se tive dado erro pergunta de novo

    call exibir_resultado

    jmp .Lperguntar_cont
    
.Lperguntar_cont:
    #imprime a pergunta de continua
    movq $msg_cont, %rsi
    movq $msg_cont_l, %rdx
    call imprimir_string

    #le a resp do teclado
    movq $buf_entrada, %rsi
    movq $2, %rdx #le 2 bytes: caractere + /n
    call ler_teclado

    movq $buf_entrada, %rsi
    movb (%rsi), %al
    cmpb $'s', %al
    je .Lloop
    cmpb $'S', %al
    je .Lloop

    popq %rbp
    ret

imprimir_string:
    movq $SYS_WRITE, %rax
    movq $STDOUT, %rdi
    syscall
    ret

ler_teclado:
    movq $SYS_READ, %rax
    movq $STDIN, %rdi
    syscall
    ret

salvar_funcao:
    #primeiro pega a letra da funcao
    movq $buf_entrada, %rsi
    movb (%rsi), %al #le um byte
    movzbq %al, %rax #zerei o rax pra ficar so com o byte lido
    #calcula o indice dela no vetor 
    subq $'a', %rax #fiz letra - a, pra achar a posicao do vetor
    imulq $20, %rax #cada parte do vetor tem 20 bytes, ai multiplica por 20
    addq $funcoes, %rax #pego endereco da funcao e somo com onde ta o rax pra aponta no lugar certo
    movq %rax, %rdi #troco rax por rdi pra guarda o endereco e poder usa zero

    #achar o = da string
    movq $buf_entrada, %rsi #li de novo o buf de entrada e guardei em rsi

.Lproc_op:
    movb (%rsi), %al #peguei o byte e coloquei no al

    cmpb $'=', %al #vi se o al é igual a =
    je .Lacho_igual # acho o igual

    incq %rsi #se nao for, eu incremento um e recomeço o loop
    jmp .Lproc_op #nao foi o fim e nao tem =,ai a gnt anda um p direita

.Lacho_igual:
    incq %rsi #passei do igual
    #tenho q pega cada um dos caracter e salvar, p coloca no vetor
    # ex: f(x) = x + 5, ai eut to com x + 5
.Lloop_copia:
    movb (%rsi), %al #copiei o primeiro byte e coloquei no al x + 5

    cmpb $10, %al # se for \n, ele da jump pro final do loop
    je .Lfim_loop_copia

    movb %al, (%rdi) #coloca o que tava em %al no endereco q ta rdi
    incq %rsi #aumento um no rsi, que ta com a funcao +5
    incq %rdi #aumento um no rdi, pra escreve na proxima parte da funcao 
    jmp .Lloop_copia #continuo ate o \n

.Lfim_loop_copia:
    movb $0, (%rdi) #coloco um \0 no final da funcao
    ret #retorno
    
preparar_chamada:
    movq $buf_entrada, %rsi

    #tem q fazer um loop tem parenteses f(5) ou f
.Lverifica_parent:
    movb (%rsi), %al

    cmpb $10, %al
    je .Lsem_parent 

    cmpb $0, %al
    je .Lsem_parent 

    cmpb $'(', %al
    je .Lcom_parent

    incq %rsi
    jmp .Lverifica_parent
    
# aceitar só a
.Lsem_parent:
    movq $buf_entrada, %rsi
    movb (%rsi), %al
    movzbq %al, %rax
    subq $'a', %rax
    imulq $20, %rax
    addq $funcoes, %rax
    movq %rax, %rdi
    
    movq $buf_op1, %rcx
.Lcopia_sem:
    movb (%rdi), %al

    cmpb $0, %al
    je .Lfim_copia_sem

    movb %al, (%rcx)
    incq %rcx
    incq %rdi
    jmp .Lcopia_sem

.Lfim_copia_sem:
    movb $0, (%rcx)
    movb $'+', operador(%rip)
    movb $'0', buf_op2(%rip)
    movb $0, buf_op2+1(%rip)
    jmp .Lfinal_salva
    
.Lcom_parent:
    # x + 5
    # 5 + x
    # x + x

    #Primeiro ver se é numero ou variável
    
    
    
    movq $buf_entrada, %rsi
    movb (%rsi), %al
    movzbq %al, %rax
    subq $'a', %rax #achei a pos do vetor
    imulq $20, %rax
    addq $funcoes, %rax
    movq %rax, %rdi

    movq $buf_entrada, %rsi
#f(5)
#f(a)
.Lloop_acha_num:
    movb (%rsi), %al 

    cmpb $'(', %al
    je .Lacho_parenteses

    incq %rsi
    jmp .Lloop_acha_num
    
.Lacho_parenteses:
    movq $buf_op1, %rcx
    incq %rsi

.Lcopia_num_um:
    movb (%rsi), %al

    cmpb $')', %al
    je .Lcopia_op

    movb %al, (%rcx)
    incq %rcx
    incq %rsi

    jmp .Lcopia_num_um

.Lcopia_op:
    movb $0, (%rcx) #coloco um \0 no final da funcao

    incq %rdi
    movb (%rdi), %al
    movb %al, operador(%rip)

    incq %rdi

    movq $buf_op2, %rcx 

.Lcopia_num_dois:
    movb (%rdi), %al

    cmpb $0, %al
    je .Lfinal_salva

    movb %al, (%rcx)
    incq %rcx
    incq %rdi

    jmp .Lcopia_num_dois

.Lfinal_salva:
    movb $0, (%rcx)
    ret

ler_operando:
    pushq %rbp
    movq  %rsp, %rbp

    movq $0, %rax
    movq $0, %rcx
    movq $0, %r8
    movq $0, %r9
    movq $0, %r10

.Ller_digito:
    movb (%rsi), %cl 

    cmpb $10, %cl
    je .Lfim_leitura

    cmpb $0, %cl
    je .Lfim_leitura

    cmpb $'-', %cl
    je .Lmarcar_negativo

    cmpb $'.', %cl
    je .Lmarcar_ponto 

    cmpq $1, %r9
    je .Lcontar_casa

    subb $'0', %cl

    imulq $10, %rax
    addq %rcx, %rax

    incq %rsi

    jmp .Ller_digito

.Lcontar_casa:
    incq %r8
    
    subb $'0', %cl
    
    imulq $10, %rax
    addq %rcx, %rax

    incq %rsi

    jmp .Ller_digito

.Lmarcar_negativo:
    incq %rsi
    incq %r10
    jmp .Ller_digito

.Lmarcar_ponto:
    incq %rsi
    incq %r9
    jmp .Ller_digito

.Lfim_leitura:
    cmpq $1, %r10
    jne .Lfim_ret
    negq %rax

.Lfim_ret:
    popq %rbp
    ret

converter_para_float:

    cvtsi2sd %rax, %xmm0
    movsd const_um(%rip), %xmm3
    movsd const_dez(%rip), %xmm2

    cmpq $0, %r8
    je .Lconverte_fim

.Lmultiplica_acc:

    mulsd %xmm2, %xmm3
    
    decq %r8
    cmpq $0, %r8
    jne .Lmultiplica_acc
    
    divsd %xmm3, %xmm0

.Lconverte_fim:
    ret

exibir_resultado:
    pushq %rbp
    movq  %rsp, %rbp

    pushq %rax
    movq $msg_res, %rsi
    movq $msg_res_l, %rdx
    call imprimir_string
    popq %rax
    
    xorpd %xmm1, %xmm1
    ucomisd %xmm1, %xmm0
    jae .Lnum_positivo

    movq $msg_sinal_menos, %rsi
    movq $1, %rdx
    call imprimir_string

    subsd %xmm0, %xmm1
    movsd %xmm1, %xmm0

.Lnum_positivo:
    cvttsd2si %xmm0, %rax 
    movq %rax, %r12

.print_numero:
    movq $10, %r8
    movq $buf_out, %rdi
    addq $63, %rdi

.Lconverter_digito:
    cqo
    idivq %r8
    addb $'0', %dl
    decq %rdi
    movb %dl, (%rdi)
    cmpq $0, %rax
    jne .Lconverter_digito

    movq %rdi, %rsi
    movq $buf_out, %rdx
    addq $64, %rdx
    subq %rsi, %rdx
    call imprimir_string     

    movq $msg_ponto, %rsi
    movq $1, %rdx
    call imprimir_string

    cvtsi2sd %r12, %xmm1
    subsd %xmm1, %xmm0

    movq $4, %r13

.Limprime_decimal:
    mulsd const_dez(%rip), %xmm0
    cvttsd2si %xmm0, %rax
    
    cvtsi2sd %rax, %xmm1
    subsd %xmm1, %xmm0

    addb $'0', %al
    movb %al, buf_out(%rip)
    
    movq $buf_out, %rsi
    movq $1, %rdx
    call imprimir_string

    decq %r13 

    xorpd %xmm4, %xmm4
    ucomisd %xmm4, %xmm0
    je .Lfim_deci

    jnz .Limprime_decimal

.Lfim_deci:
    movq $msg_nl, %rsi
    movq $msg_nl_l, %rdx
    call imprimir_string

    popq %rbp
    ret
