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

.align 8 #o align garante que essas constantes estejam alinhadas em múltiplos de 8, não muda nada no código em si, mas otimiza o acesso a memoria
const_dez: .double 10.0 
.align 8 
const_um: .double 1.0
.align 8 
const_dois: .double 2.0
.align 8 
const_arred: .double 0.99

# Seção de dados não inicializados
.section .bss

buf_op1: .space 64 # buffer de entrada operador 1
buf_op2: .space 64
buf_out: .space 64 # buffer de saída (resultado convertido)
operador: .space 4 # char do operador

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
    movb operador(%rip), %al

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

    movb buf_op1(%rip), %al

    # se sim, jmp .Lloop
    cmpb $'s', %al
    je .Lloop

    popq %rbp
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

executar_operacao:
    pushq %rbp
    movq  %rsp, %rbp

    movzbq operador(%rip), %rax

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

# Operações binárias
.Lop_soma:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    addsd %xmm1, %xmm0

    jmp .Lop_fim

.Lop_sub:
    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    subsd %xmm1, %xmm0

    jmp .Lop_fim

.Lop_mul:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    mulsd %xmm1, %xmm0

    jmp .Lop_fim

.Lop_div:
    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0, %xmm1

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2

    ucomisd %xmm2, %xmm1
    je .Lerro_div

    divsd %xmm1, %xmm0

    jmp .Lop_fim

.Lerro_div:
    movq $msg_erro_div, %rsi
    movq $msg_erro_div_l, %rdx
    call imprimir_string

    jmp .Lloop

.Lop_pow:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0, %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    cvttsd2si %xmm0, %rcx

    movsd const_um(%rip), %xmm0 

    cmpq $0, %rcx
    je .Lfim_da_potencia

.Lloop_pow:
    mulsd %xmm1, %xmm0
    decq %rcx

    cmp $0, %rcx
    jne .Lloop_pow

.Lfim_da_potencia:
    jmp .Lop_fim

.Lop_comb:
    # fazer aq
    #n! / r! * (n - r)!

    pushq %rbx
    pushq %r12
    pushq %r13

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx #leu n

    cvtsi2sd %rbx, %xmm1
    ucomisd %xmm1, %xmm0
    jne .Lerro_fat

    cmpq $0, %rbx
    jl .Lerro_fat

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %r12 #leu r

    cvtsi2sd %r12, %xmm1
    ucomisd %xmm1, %xmm0
    jne .Lerro_fat

    cmpq $0, %r12
    jl .Lerro_fat

    cmpq %r12, %rbx
    jl .Lerro_num_menor

    movq %rbx, %r13
    subq %r12, %r13
    
    movq %rbx, %rax
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx
    
    movq %r12, %rax
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %r12

    movq %r13, %rax
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %r13

    imulq %r12, %r13

    movq %rbx, %rax
    cqo
    idivq %r13

    popq %r13
    popq %r12
    popq %rbx

    cvtsi2sd %rax, %xmm0
    jmp .Lop_fim

.Lop_arr:
    pushq %rbx
    pushq %r12

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx

    cvtsi2sd %rbx, %xmm1 
    ucomisd %xmm1, %xmm0
    jne .Lerro_fat

    cmpq $0, %rbx
    jl .Lerro_fat

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax

    cvtsi2sd %rax, %xmm1
    ucomisd %xmm1, %xmm0
    jne .Lerro_fat

    cmpq $0, %rax
    jl .Lerro_fat

    cmpq %rax, %rbx
    jl .Lerro_num_menor

    movq %rbx, %r12
    subq %rax, %r12 

    movq %rbx, %rax
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx 

    movq %r12, %rax 
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %r12 

    movq %rbx, %rax 
    cqo
    idivq %r12

    popq %r12
    popq %rbx

    cvtsi2sd %rax, %xmm0
    jmp .Lop_fim

.Lerro_num_menor:
    movq $msg_erro_ord, %rsi
    movq $msg_erro_ord_l, %rdx
    call imprimir_string

    jmp .Lloop

.Lop_fat:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    cvttsd2si %xmm0, %rax

    cvtsi2sd %rax, %xmm1
    ucomisd %xmm1, %xmm0
    jne .Lerro_fat

    cmpq $0, %rax
    jl .Lerro_fat

    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax

    cvtsi2sd %rax, %xmm0
    jmp .Lop_fim

.Lerro_fat:
    movq $msg_erro_neg, %rsi
    movq $msg_erro_neg_l, %rdx 
    call imprimir_string

    jmp .Lloop

.Lop_inv:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0, %xmm1
    movsd const_um(%rip), %xmm0

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm1
    je .Lerro_inv
    
    divsd %xmm1, %xmm0

    jmp .Lop_fim

.Lerro_inv:
    movq $msg_erro_inv, %rsi
    movq $msg_erro_inv_l, %rdx
    call imprimir_string

    jmp .Lloop

.Lop_sqrt:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jb .Lsqrt_erro 
    
    sqrtsd %xmm0, %xmm0

    jmp .Lop_fim

.Lsqrt_erro:
    movq $msg_erro_sqrt, %rsi
    movq $msg_erro_sqrt_l, %rdx
    call imprimir_string

    jmp .Lloop

.Lop_log:
#propriedade dos logaritmos: log_{base} = ln_{num}/ln_{base} 
    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jbe .Llog_erro

    ucomisd const_um(%rip), %xmm0
    je .Llog_erro

    call log #essa funcao devolve o ln
    movsd %xmm0, %xmm1

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jbe .Llog_erro
    
    call log
    
    divsd %xmm1, %xmm0
    jmp .Lop_fim

.Llog_erro:
    movq $msg_erro_log, %rsi
    movq $msg_erro_log_l, %rdx
    call imprimir_string

    jmp .Lloop

.Lop_primo:
 #Primeiro, vc vê se é 1 ou 2
 #pq se for é primo
 #dps, vc começa uma contagem em 2
 #ai vc vai tentando dividir o num por esse valor e vê se dá 0 no resto (%rdx)
 #ai se der zero, você sai do loop, e incrementa +1, aí tenta de novo dividir tudo
 #ai se todas as divisões não deram resto 0, significa que é o número primo mais próximo
 #10
 # 10/2 %rdx = 0? se sim, já não é primo
 # 10/3
 # 10/4
 # ...
 #11
 #11/2
 #...
 #rdx ficou zero? não, então 11 é o primo mais próximo
 # Q tem todos os operadores até a raiz mais próxima dele
 # Se vc tem 10
 # 3
 #10/2
 #10/3
 #1. verificar se o número é par e maior que 2: se for já incrementa 1 e testar
 #2. depois, incrementar de 2 em 2, porque aí vai testar sempre os ímpares só

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    
    addsd const_arred(%rip), %xmm0

    cvttsd2si %xmm0, %rax
    
    cmpq $2, %rax 
    cvtsi2sd %rax, %xmm0  # Converte o resultado inteiro de %rax para o float %xmm0 
    jle .Lop_fim 

    movq %rax, %rcx

.Lprimo_loop:

    movq $2, %r8 

.Lprimo_divisor:

    movq %r8, %rax  
    imulq %r8, %rax 

    cmpq %rcx, %rax
    jg .Lprimo_fim

    movq %rcx, %rax
    cqo
    idivq %r8

    cmpq $0, %rdx
    je .Lprimo_nao
    
    addq $1, %r8
    jmp  .Lprimo_divisor

.Lprimo_nao:

    incq %rcx
    jmp .Lprimo_loop

.Lprimo_fim:

    movq %rcx, %rax
    cvtsi2sd %rax, %xmm0

.Lop_fim:
    popq %rbp
    ret

# ---------------------------------------
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

calcular_fatorial:
    cvttsd2si %xmm0, %rax
    movq %rax, %rcx
    movq $1, %rax
    cvtsi2sd %rax, %xmm0

    cmpq $1, %rcx
    jle .Lfim_fat

.Lfat:
    cvtsi2sd %rcx, %xmm1
    mulsd %xmm1, %xmm0
    
    decq %rcx
    cmpq $1, %rcx
    jne .Lfat

.Lfim_fat:
    ret

log:
    subq $8, %rsp
    movsd %xmm0, (%rsp)

    fldln2
    fldl (%rsp)

    fyl2x
    fstpl (%rsp)
    movsd (%rsp), %xmm0

    addq $8, %rsp
    ret
