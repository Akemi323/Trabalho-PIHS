.section .rodata

msg_erro_op: .string "Erro: operador invalido\n"
msg_erro_op_l = . - msg_erro_op

msg_erro_div: .string "Erro: divisao por zero\n"
msg_erro_div_l = . - msg_erro_div

msg_erro_neg: .string "Erro: operando invalido (negativo ou nao inteiro)\n"
msg_erro_neg_l = . - msg_erro_neg

msg_erro_sqrt: .string "Erro: raiz de numero negativo\n"
msg_erro_sqrt_l = . - msg_erro_sqrt

msg_erro_inv: .string "Erro: inverso de zero\n"
msg_erro_inv_l = . - msg_erro_inv

msg_erro_log:.string "Erro: logaritmando <= 0 ou base invalida\n"
msg_erro_log_l = . - msg_erro_log

msg_erro_ord:  .string "Erro: n deve ser >= r\n"
msg_erro_ord_l = . - msg_erro_ord

msg_nl:     .string "\n"
msg_nl_l = . - msg_nl

.align 8
const_dez_op: .double 10.0 
.align 8 
const_um_op: .double 1.0
.align 8 
const_dois: .double 2.0
.align 8 
const_arred: .double 0.99


.section .text

.global executar_operacao

#Executa a operação conforme o caractere do operador
#Entradas: buf_op1, buf_op2 e operador
#Saídas: %xmmo = resultado, %rax = 0(Ok) ou 1(Erro)
executar_operacao:
    pushq %rbp
    movq  %rsp, %rbp

    movzbq operador(%rip), %rax

    cmpb $'+', %al
    jne .Ltesta_sub
    call op_soma
    jmp .Lfim

.Ltesta_sub:
    cmpb $'-', %al
    jne .Ltesta_mul
    call op_sub
    jmp .Lfim

.Ltesta_mul:
    cmpb $'*', %al
    jne .Ltesta_div
    call op_mul
    jmp .Lfim

.Ltesta_div:
    cmpb $'/', %al
    jne .Ltesta_pow
    call op_div
    jmp .Lfim

.Ltesta_pow:
    cmpb $'^', %al
    jne .Ltesta_comb
    call op_pow
    jmp .Lfim

.Ltesta_comb:
    cmpb $'c', %al
    jne .Ltesta_arr
    call op_comb
    jmp .Lfim

.Ltesta_arr:
    cmpb $'a', %al
    jne .Ltesta_fat
    call op_arr
    jmp .Lfim

.Ltesta_fat:
    cmpb $'!', %al
    jne .Ltesta_inv
    call op_fat
    jmp .Lfim

.Ltesta_inv:
    cmpb $'i', %al
    jne .Ltesta_sqrt
    call op_inv
    jmp .Lfim

.Ltesta_sqrt:
    cmpb $'r', %al
    jne .Ltesta_log
    call op_sqrt
    jmp .Lfim

.Ltesta_log:
    cmpb $'l', %al
    jne .Ltesta_primo
    call op_log
    jmp .Lfim

.Ltesta_primo:
    cmpb $'p', %al
    jne .Lteste_invalido
    call op_primo
    jmp .Lfim

.Lteste_invalido:
    movq $1, %rax #jogar na main que se retornar zero ele roda o loop de novo
    movq %rbp, %rsp
    popq %rbp
    ret

.Lfim:
    movq %rbp, %rsp
    popq %rbp
    ret
    
#Realiza a soma do número de entrada em buf_op1 pelo buf_op2
#Retorna o resultado em %xmm0
op_soma:
    pushq %rbp
    movq  %rsp, %rbp

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    addsd %xmm1, %xmm0

    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret  

#Realiza a subtração do número de entrada em buf_op1 pelo buf_op2 
#Retorna o resultado em %xmm0
op_sub:
    push %rbp
    movq %rsp, %rbp

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    subsd %xmm1, %xmm0

    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret

#Realiza a multiplicação do número de entrada em buf_op1 pelo buf_op2
#Retora o resultado em %xxm0
op_mul:
    push %rbp
    movq %rsp, %rbp

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    mulsd %xmm1, %xmm0

    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret

#Realiza a divisão do número de entrada em buf_op1 pelo buf_op2
#Retorna o resultado em %xmm0
op_div:
    push %rbp
    movq %rsp, %rbp

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
    movq $0, %rax # sucesso
    jmp .Lfim_div

.Lerro_div:
    movq $msg_erro_div, %rsi
    movq $msg_erro_div_l, %rdx
    call imprimir_string
    movq $1, %rax

.Lfim_div:
    movq %rbp, %rsp
    popq %rbp
    ret

#Realiza a potenciação do número de entrada em buf_op1 pelo buf_op2 
#Retorna o resultado em %xmm0
op_pow:
    push %rbp
    movq %rsp, %rbp

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0, %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    cvttsd2si %xmm0, %rcx

    movsd const_um_op(%rip), %xmm0 

    cmpq $0, %rcx
    je .Lfim_da_potencia

.Lloop_pow:
    mulsd %xmm1, %xmm0
    decq %rcx

    cmp $0, %rcx
    jne .Lloop_pow

.Lfim_da_potencia:
    movq $0, %rax
    popq %rbp
    ret

#Executa a operação de combinação n! / (r! * (n-r)!)
#Entradas: buf_op1 = n e buf_op2 = r
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
op_comb:
    push %rbp
    movq %rsp, %rbp
    
    pushq %rax
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
    jne .Lerro_fat_comb # se diferente, tinha parte decimal

    cmpq $0, %rbx
    jl .Lerro_fat_comb

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %r12 #leu r

    cvtsi2sd %r12, %xmm1
    ucomisd %xmm1, %xmm0
    jne .Lerro_fat_comb

    cmpq $0, %r12
    jl .Lerro_fat_comb

    cmpq %r12, %rbx
    jl .Lerro_num_menor_comb

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

    cvtsi2sd %rax, %xmm0

    movq $0, %rax 
    jmp .Lfim_comb

.Lerro_fat_comb:
    movq $msg_erro_neg, %rsi
    movq $msg_erro_neg_l, %rdx
    call imprimir_string

    movq $1, %rax 
    jmp .Lfim_comb

.Lerro_num_menor_comb:
    movq $msg_erro_ord, %rsi
    movq $msg_erro_ord_l, %rdx
    call imprimir_string

    movq $1, %rax

.Lfim_comb:
    addq $8, %rsp
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de arranjo n! / (n-r)!
#Entradas: buf_op1 = n e buf_op2 = r
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
op_arr:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx

    cvtsi2sd %rbx, %xmm1 
    ucomisd %xmm1, %xmm0
    jne .Lerro_fat_arr

    cmpq $0, %rbx
    jl .Lerro_fat_arr

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax

    cvtsi2sd %rax, %xmm1
    ucomisd %xmm1, %xmm0
    jne .Lerro_fat_arr

    cmpq $0, %rax
    jl .Lerro_fat_arr

    cmpq %rax, %rbx
    jl .Lerro_num_menor_arr

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

    cvtsi2sd %rax, %xmm0
    movq $0, %rax
    jmp .Lfim_arr

.Lerro_fat_arr:
    movq $msg_erro_neg, %rsi
    movq $msg_erro_neg_l, %rdx
    call imprimir_string
    movq $1, %rax

    jmp .Lfim_arr

.Lerro_num_menor_arr:
    movq $msg_erro_ord, %rsi
    movq $msg_erro_ord_l, %rdx
    call imprimir_string
    movq $1, %rax 

.Lfim_arr:
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de fatorial n!
#Entrada: buf_op1 = 
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
op_fat:
    pushq %rbp
    movq %rsp, %rbp

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
    movq $0, %rax
    jmp .Lfim_fat
    
.Lerro_fat:
    movq $msg_erro_neg, %rsi
    movq $msg_erro_neg_l, %rdx 
    call imprimir_string
    movq $1, %rax

.Lfim_fat:
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de inverso 1/x
#Entrada: buf_op1 = x
#Saídas: %xmmo = resultado, %rax = 0(Ok) ou 1(Erro)
op_inv:
    pushq %rbp
    movq %rsp, %rbp

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0, %xmm1
    movsd const_um_op(%rip), %xmm0

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm1
    je .Lerro_inv
    
    divsd %xmm1, %xmm0

    movq $0, %rax
    jmp .Lfim_inv

.Lerro_inv:
    movq $msg_erro_inv, %rsi
    movq $msg_erro_inv_l, %rdx
    call imprimir_string
    movq $1, %rax

.Lfim_inv:
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de raiz quadrada
#Entrada: buf_op1
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
op_sqrt:
    push %rbp
    movq %rsp, %rbp

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jb .Lsqrt_erro 
    
    sqrtsd %xmm0, %xmm0

    movq $0, %rax
    jmp .Lfim_sqrt

.Lsqrt_erro:
    movq $msg_erro_sqrt, %rsi
    movq $msg_erro_sqrt_l, %rdx
    call imprimir_string
    movq $1, %rax

.Lfim_sqrt:
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de logaritmo log_base(x) = ln(x)/ln(base)
#Entrada: buf_op1 = x e buf_op2 = base
#Saídas: %xmm0 = resultado, %rax = 0(Ok) ou 1(Erro)
op_log: 
    push %rbp
    movq %rsp, %rbp

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jbe .Llog_erro

    ucomisd const_um_op(%rip), %xmm0
    je .Llog_erro

    call log
    movsd %xmm0, %xmm1

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jbe .Llog_erro
    
    call log
    
    divsd %xmm1, %xmm0
    movq $0, %rax
    jmp .Lfim_log

.Llog_erro:
    movq $msg_erro_log, %rsi
    movq $msg_erro_log_l, %rdx
    call imprimir_string
    movq $1, %rax

.Lfim_log:
    movq %rbp, %rsp
    popq %rbp
    ret

#Executa a operação de próximo primo >= x
#Entrada: buf_op1 = x
#Saídas: %xmmo = primo encontrado, %rax = 0(Ok) ou 1(Erro)
op_primo:
    push %rbp
    movq %rsp, %rbp

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    
    addsd const_arred(%rip), %xmm0

    cvttsd2si %xmm0, %rax
    
    cmpq $2, %rax 
    cvtsi2sd %rax, %xmm0  # Converte o resultado inteiro de %rax para o float %xmm0 
    jle .Lprimo_fim

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

    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
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
    jle .Lfim_fatorial

.Lfat:
    cvtsi2sd %rcx, %xmm1
    mulsd %xmm1, %xmm0
    
    decq %rcx
    cmpq $1, %rcx
    jne .Lfat

.Lfim_fatorial:
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
