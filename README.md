# Calculadora x86-64

**Disciplina:** Programação para Interfaceamento de Hardware e Software  
**Instituição:** Universidade Estadual de Maringá 
**Dupla:**
- Nome: Letícia Akemi Nakahati Vieira - RA: 140535
- Nome: Pedro Henrique Pereira da Silva - RA: 

---

## Descrição

Trabalho 1 da disciplina:
Calculadora implementada em linguagem assembly x86-64 com sintaxe AT&T (GAS), sem uso da biblioteca C (libc). Toda a entrada e saída é feita diretamente via syscalls do Linux. O programa aceita operandos reais e realiza operações aritméticas, combinatórias e matemáticas, exibindo o resultado e perguntando se o usuário deseja continuar.

Trabalho 2 da disciplina:

Armazenamento de funções
Passagem dos parâmetros linha por linha

Foi escolhido a realização de ambas as partes sem o uso da Libc, considerando que o trabalho 2 não permitiria esse uso

---

## Operações suportadas

| Operador | Operação | Operandos |
|----------|----------|-----------|
| `+` | Soma | dois |
| `-` | Subtração | dois |
| `*` | Multiplicação | dois |
| `/` | Divisão | dois |
| `^` | Exponenciação (base ^ expoente) | dois |
| `c` | Combinação simples C(n, r) | dois |
| `a` | Arranjo simples A(n, r) | dois |
| `l` | Logaritmo (1º operando na base do 2º) | dois |
| `!` | Fatorial | um |
| `i` | Inverso (1 ÷ número) | um |
| `r` | Raiz quadrada | um |
| `p` | Próximo primo ≥ número | um |

---

## Validações

- **Divisão:** informa erro se o divisor for zero.
- **Fatorial, combinação e arranjo:** informa erro se algum operando for negativo ou não inteiro.
- **Combinação e arranjo:** informa erro se n < r.
- **Raiz quadrada:** informa erro se o operando for negativo.
- **Inverso:** informa erro se o operando for zero.
- **Logaritmo:** informa erro se o logaritmando for ≤ 0 ou se a base for ≤ 0 ou igual a 1.

---

## Como compilar e executar

```bash
# Montar (assemblar)
as -o calculadora.o calculadora.s

# Linkar
ld -o calculadora calculadora.o

# Executar
./calculadora
```

---

## Exemplos de uso

```
Digite o primeiro operando: 10
Digite o operador: +
Digite o segundo operando: 5
Resultado: 15

Continuar? (s/n): s

Digite o primeiro operando: 9
Digite o operador: r
Resultado: 3

Continuar? (s/n): s

Digite o primeiro operando: 5
Digite o operador: !
Resultado: 120

Continuar? (s/n): s

Digite o primeiro operando: 10
Digite o operador: c
Digite o segundo operando: 3
Resultado: 120

Continuar? (s/n): s

Digite o primeiro operando: 100
Digite o operador: l
Digite o segundo operando: 10
Resultado: 2

Continuar? (s/n): n
```

---


# Trabalho 2

param:    1 byte   (ex: 'x')
operador: 1 byte   (ex: '*')
flag_esq: 1 byte   (0=número, 1=variável)
val_esq:  8 bytes  (double ou código da letra)
flag_dir: 1 byte   (0=número, 1=variável)
val_dir:  8 bytes  (double ou código da letra)

Fazer um vetor, que tem 26 funções (de A a Z)

.bss
funcoes: .space 520    # 26 funções * 20 bytes cada


endereço = funcoes + (índice * 20) -> Para acessa a função

Pra saber se é definir função ou puxar função, procura pelo igual

achou = → é definição
não achou = (chegou no \n) → é chamada

movq $buf_entrada, %rsi
movb (%rsi), %al        # nome: f
movb 2(%rsi), %al       # parâmetro: x
movb 5(%rsi), %al       # op. esquerdo: x
movb 6(%rsi), %al       # operador: *
movb 7(%rsi), %al       # op. direito: 3

Pegar o índice de f no vetor
Ler os campos armazenados
Substituir o parâmetro pelo valor 3 onde aparecer
Calcular o resultado

1. lê f → pega entrada no vetor
2. lê 3 → esse é o valor do parâmetro
3. checa flag_esq:
   - 0 → usa val_esq como está
   - 1 → usa o valor 3 no lugar
4. checa flag_dir:
   - 0 → usa val_dir como está
   - 1 → usa o valor 3 no lugar
5. aplica o operador entre os dois valores
6. imprime o resultado


#1. Ler uma linha do teclado

#2. Buscar '=' na linha
   #- achou → é definição → chama função parsear_definicao
   #- não achou → é chamada → chama função parsear_chamada

#3. parsear_definicao:
   #- extrai nome, parâmetro, op. esquerdo, operador, op. direito
   #- calcula índice no vetor
   #- armazena tudo no vetor

#4. parsear_chamada:
   #- extrai nome da função e valor passado
   #- calcula índice no vetor
   #- lê os campos armazenados
   #- substitui parâmetro pelo valor onde flag=1
   #- chama função calcular com os dois operandos e o operador
   #- imprime o resultado

#5. Perguntar se continua ou volta pro passo 1

f(x)=x+3

nome = f(x)
op. esquerdo = x
operando = +
op. direita = 3

f(x)

