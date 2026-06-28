.equ SYS_READ,   0
.equ SYS_WRITE,  1
.equ SYS_EXIT,   60
.equ STDIN,      0
.equ STDOUT,     1

# Seção de dados somente leitura
.section .rodata

msg_op1:    .string "Digite o primeiro operando: "
msg_op1_l = . - msg_op1

msg_oper:   .string "Digite o operador: "
msg_oper_l = . - msg_oper

msg_op2:    .string "Digite o segundo operando: "
msg_op2_l = . - msg_op2

msg_res:    .string "Resultado: "
msg_res_l = . - msg_res

msg_cont:   .string "Continuar? (s/n): "
msg_cont_l = . - msg_cont

msg_erro_op:  .string "Erro: operador invalido\n"
msg_erro_op_l = . - msg_erro_op

msg_erro_div:  .string "Erro: divisao por zero\n"
msg_erro_div_l = . - msg_erro_div

msg_erro_neg:  .string "Erro: operando invalido (negativo ou nao inteiro)\n"
msg_erro_neg_l = . - msg_erro_neg

msg_erro_sqrt: .string "Erro: raiz de numero negativo\n"
msg_erro_sqrt_l = . - msg_erro_sqrt

msg_erro_inv:  .string "Erro: inverso de zero\n"
msg_erro_inv_l = . - msg_erro_inv

msg_erro_log:  .string "Erro: logaritmando <= 0 ou base invalida\n"
msg_erro_log_l = . - msg_erro_log

msg_erro_ord:  .string "Erro: n deve ser >= r\n"
msg_erro_ord_l = . - msg_erro_ord

msg_nl:     .string "\n"
msg_nl_l = . - msg_nl

msg_ponto: .string "."

msg_sinal_menos: .ascii "-"

const_dez: .double 10.0
const_um: .double 1.0
const_dois: .double 2.0
const_arred: .double 0.99

# Seção de dados não inicializados
.section .bss

buf_op1: .space 64       # buffer de entrada operador 1
buf_op2: .space 64
buf_out: .space 64       # buffer de saída (resultado convertido)
operador: .space 4        # char do operador

# Seção de código 
.section .text
.global _start

_start:
    call loop_principal

    # Encerrar processo
    movq $SYS_EXIT, %rax
    movq $0,        %rdi
    syscall

loop_principal:
    pushq %rbp
    movq  %rsp, %rbp

.Lloop:
    # Pedir e ler primeiro operando 
    movq $msg_op1, %rsi
    movq $msg_op1_l, %rdx
    call imprimir_string

    movq $buf_op1, %rsi
    movq $64, %rdx
    call ler_teclado

    # Pedir e ler operador
    movq $msg_oper, %rsi
    movq $msg_oper_l, %rdx
    call imprimir_string

    movq $operador, %rsi
    movq $4, %rdx
    call ler_teclado

    # Verificar se é operação unária ou binária
    movb operador, %al

    cmpb $'!', %al
    je .Lpular_op2
    
    cmpb $'i', %al
    je .Lpular_op2

    cmpb $'r', %al
    je .Lpular_op2

    cmpb $'p', %al
    je .Lpular_op2

    cmpb $'+', %al
    je .Ller_op2

    cmpb $'-', %al
    je .Ller_op2

    cmpb $'*', %al
    je .Ller_op2
    
    cmpb $'/', %al
    je .Ller_op2

    cmpb $'^', %al
    je .Ller_op2

    cmpb $'c', %al
    je .Ller_op2

    cmpb $'a', %al
    je .Ller_op2
    
    cmpb $'l', %al
    je .Ller_op2

    movq $msg_erro_op, %rsi
    movq $msg_erro_op_l, %rdx
    call imprimir_string
    jmp .Lloop

    # (se binária) Pedir e ler segundo operando
.Ller_op2:
    movq $msg_op2, %rsi
    movq $msg_op2_l, %rdx
    call imprimir_string

    movq $buf_op2, %rsi
    movq $64, %rdx
    call ler_teclado

    # Unárias: !, i, r, p -  não lê segundo operando
.Lpular_op2:    

    # Executar a operação 
    call executar_operacao

    # Exibir resultado
    call exibir_resultado

    # Perguntar se continua
    movq $msg_cont, %rsi
    movq $msg_cont_l, %rdx
    call imprimir_string

    movq $buf_op1, %rsi
    movq $64, %rdx
    call ler_teclado

    movb buf_op1, %al

    # se sim, jmp .Lloop
    cmpb $'s', %al
    je .Lloop

    popq %rbp
    ret

ler_operando:
    pushq %rbp
    movq  %rsp, %rbp

    # Tem q fazer coisa
    movq $0, %rax
    movq $0, %rcx
    movq $0, %r8
    movq $0, %r9

.Ller_digito:
    movb (%rsi), %cl 

    cmpb $10, %cl
    je .Lfim_leitura

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

.Lmarcar_ponto:
    incq %rsi
    incq %r9
    jmp .Ller_digito

.Lfim_leitura:
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
    jae .Lnum_positivo         # Se for positivo (>= 0), pula o sinal

    movq $msg_sinal_menos, %rsi
    movq $1, %rdx
    call imprimir_string

    # Transforma o %xmm0 em positivo (0.0 - número_negativo = número_positivo)
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

.Lloop_aa:
    mulsd const_dez(%rip), %xmm0
    cvttsd2si %xmm0, %rax
    
    cvtsi2sd %rax, %xmm1      # %xmm1 = 3.0
    subsd %xmm1, %xmm0

    addb $'0', %al            # Transforma o inteiro 3 no caractere '3'
    movb %al, buf_out(%rip)

    
    movq $buf_out, %rsi       # %rsi = Onde está o caractere
    movq $1, %rdx             # %rdx = Tamanho (1 byte)
    call imprimir_string

    decq %r13

    xorpd %xmm4, %xmm4
    ucomisd %xmm4, %xmm0
    je .Lfim_deci

    jnz .Lloop_aa

.Lfim_deci:
    movq $msg_nl, %rsi
    movq $msg_nl_l, %rdx
    call imprimir_string

    popq %rbp
    ret

executar_operacao:
    pushq %rbp
    movq  %rsp, %rbp

    movzbq operador(%rip), %rax   # carrega char do operador

    cmpb $'+', %al
    je   .Lop_soma

    cmpb $'-', %al
    je   .Lop_sub

    cmpb $'*', %al
    je   .Lop_mul

    cmpb $'/', %al
    je   .Lop_div

    cmpb $'^', %al
    je   .Lop_pow

    cmpb $'c', %al
    je   .Lop_comb

    cmpb $'a', %al
    je   .Lop_arr

    cmpb $'!', %al
    je   .Lop_fat

    cmpb $'i', %al
    je   .Lop_inv

    cmpb $'r', %al
    je   .Lop_sqrt

    cmpb $'l', %al
    je   .Lop_log

    cmpb $'p', %al
    je   .Lop_primo

# ---------------------------------------
imprimir_string:
    movq $SYS_WRITE, %rax
    movq $STDOUT,    %rdi
    # %rsi e %rdx já devem estar configurados pelo chamador
    syscall
    ret

ler_teclado:
    movq $SYS_READ, %rax
    movq $STDIN, %rdi
    syscall
    ret

