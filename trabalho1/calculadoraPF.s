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

.align 8 
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
buf_op2: .space 64 # buffer de entrada operador 2
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

    call executar_operacao

    cmpq $1, %rax
    je .Lpular_impressao

    call exibir_resultado

.Lpular_impressao:
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

    movq %rbp, %rsp
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
    movq %rbp, %rsp
    popq %rbp
    ret

converter_para_float:
    pushq %rbp
    movq %rsp, %rbp

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
    movq %rbp, %rsp
    popq %rbp
    ret

exibir_resultado:
    pushq %rbp
    movq  %rsp, %rbp

    pushq %r12
    pushq %r13

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
    cvttsd2si %xmm0, %rax #parte inteira
    movq %rax, %r12 #guarda a parte decimal

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

    popq %r13
    popq %r12

    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação conforme o caractere do operador
#Entradas: buf_op1, buf_op2 e operador
#Saídas: %xmmo = resultado, %rax = 0(Ok) ou 1(Erro)
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
#Realiza a soma do número de entrada em buf_op1 pelo buf_op2
#Retorna o resultado em %xmm0
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

#Realiza a subtração do número de entrada em buf_op1 pelo buf_op2 
#Retorna o resultado em %xmm0
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

#Realiza a multiplicação do número de entrada em buf_op1 pelo buf_op2
#Retora o resultado em %xxm0
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

#Realiza a divisão do número de entrada em buf_op1 pelo buf_op2
#Retorna o resultado em %xmm0
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

    movq $1, %rax
    movq %rbp, %rsp 
    popq %rbp
    ret

#Realiza a potenciação do número de entrada em buf_op1 pelo buf_op2 
#Retorna o resultado em %xmm0
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

#Executa a operação de combinação n! / (r! * (n-r)!)
#Entradas: buf_op1 = n e buf_op2 = r
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
.Lop_comb:
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
    ucomisd %xmm1, %xmm0 # compara int com float pra checar se era inteiro
    jne .Lcomb_erro_fat # se diferente, tinha parte decimal, que dá erro

    cmpq $0, %rbx
    jl .Lcomb_erro_fat

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %r12 #leu r

    cvtsi2sd %r12, %xmm1
    ucomisd %xmm1, %xmm0
    jne .Lcomb_erro_fat

    cmpq $0, %r12
    jl .Lcomb_erro_fat

    cmpq %r12, %rbx
    jl .Lcomb_erro_menor

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

.Lcomb_erro_fat:
    popq %r13
    popq %r12
    popq %rbx 
    jmp .Lerro_fat

.Lcomb_erro_menor:
    popq %r13
    popq %r12
    popq %rbx
    jmp .Lerro_num_menor

#Executa a operação de arranjo n! / (n-r)!
#Entradas: buf_op1 = n e buf_op2 = r
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
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
    jne .Larr_erro_fat

    cmpq $0, %rbx
    jl .Larr_erro_fat

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax

    cvtsi2sd %rax, %xmm1
    ucomisd %xmm1, %xmm0
    jne .Larr_erro_fat

    cmpq $0, %rax
    jl .Larr_erro_fat

    cmpq %rax, %rbx
    jl .Larr_erro_menor

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

.Larr_erro_fat:
    popq %r12
    popq %rbx 
    jmp .Lerro_fat

.Larr_erro_menor:
    popq %r12
    popq %rbx
    jmp .Lerro_num_menor

.Lerro_num_menor:
    movq $msg_erro_ord, %rsi
    movq $msg_erro_ord_l, %rdx
    call imprimir_string

    movq $1, %rax 
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de fatorial n!
#Entrada: buf_op1 = 
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
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

    movq $1, %rax  
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de inverso 1/x
#Entrada: buf_op1 = x
#Saídas: %xmmo = resultado, %rax = 0(Ok) ou 1(Erro)
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

    movq $1, %rax  
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de raiz quadrada
#Entrada: buf_op1
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
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

    movq $1, %rax  
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de logaritmo log_base(x) = ln(x)/ln(base)
#Entrada: buf_op1 = x e buf_op2 = base
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
.Lop_log:
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

    movq $1, %rax  
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de próximo primo >= x
#Entrada: buf_op1 = x
#Saídas: %xmmo = primo encontrado, %rax = 0(Ok) ou 1(Erro)
.Lop_primo:

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
    movq $0, %rax
    movq %rbp, %rsp
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


#Calcula o fatorial n! iterativamente
#Entrada: %xmm0 = n
#Saída: %xmm0 = n!
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

#Calcula logaritmo usando FPU x87
#Entrada = %xmm0 = x
#Saída = %xmm0 = ln(x)
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
