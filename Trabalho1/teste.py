#!/usr/bin/env python3
"""
Script de testes automatizados para a calculadora em Assembly (x86-64, AT&T/GAS).

Como usar:
    1. Coloque este script na mesma pasta do seu arquivo .s (ex: calculadora.s)
    2. Ajuste ASM_FILE abaixo se o nome do arquivo for diferente
    3. Rode: python3 testar_calculadora.py

O script monta o programa (as + ld, sem libc, já que o código usa syscalls
diretas), roda cada caso de teste simulando um terminal (via pexpect) e
compara a saída com o resultado esperado.

Requer: pexpect (pip install pexpect --break-system-packages)
"""

import pexpect
import subprocess
import sys
import re

ASM_FILE = "calculadoraPF.s"   # ajuste para o nome do seu arquivo
OBJ_FILE = "calculadora.o"
BIN_FILE = "./calculadora"
TIMEOUT = 5                   # segundos para cada leitura esperada


def montar():
    """Monta e linka o programa. Retorna True se sucesso."""
    print(f"Montando {ASM_FILE}...")
    r1 = subprocess.run(["as", "-o", OBJ_FILE, ASM_FILE], capture_output=True, text=True)
    if r1.returncode != 0:
        print("Erro na montagem (as):")
        print(r1.stderr)
        return False

    r2 = subprocess.run(["ld", "-o", BIN_FILE.lstrip("./"), OBJ_FILE], capture_output=True, text=True)
    if r2.returncode != 0:
        print("Erro no link (ld):")
        print(r2.stderr)
        return False

    print("Montagem OK.\n")
    return True


class Resultado:
    OK = "PASSOU"
    FALHOU = "FALHOU"
    ERRO = "ERRO(timeout/crash)"


def rodar_caso(nome, op1, operador, op2, esperado_regex, continuar_antes="s"):
    """
    Roda um caso de teste único.
    op2 pode ser None para operações unárias (!, i, r, p).
    esperado_regex: regex que deve casar em algum lugar da saída
                    (ex: r"Resultado: 8\\.0000" ou r"Erro: divisao por zero")
    """
    try:
        p = pexpect.spawn(BIN_FILE, encoding="utf-8", timeout=TIMEOUT)

        p.expect("primeiro operando")
        p.sendline(str(op1))

        p.expect("operador")
        p.sendline(operador)

        if op2 is not None:
            p.expect("segundo operando")
            p.sendline(str(op2))

        # Espera ou o resultado ou uma mensagem de erro, o que vier primeiro
        idx = p.expect(["Resultado:", "Erro:"])
        if idx == 0:
            p.expect("Continuar")
            saida = p.before
            saida_completa = "Resultado:" + saida
            p.sendline("n")  # encerra o programa normalmente
            p.expect(pexpect.EOF)
        else:
            # "Erro:" já foi consumido pelo match acima; ainda falta capturar
            # o resto da frase de erro, que só chega depois. Esperamos o
            # próximo prompt conhecido ("primeiro operando") para pegar tudo.
            p.expect("primeiro operando")
            saida_completa = "Erro:" + p.before

        p.close(force=True)

        # remove bytes nulos e normaliza quebras de linha, que aparecem
        # por causa dos buffers de tamanho fixo (.space 64) sendo lidos/escritos
        saida_completa = saida_completa.replace("\x00", "").replace("\r", "")

        if re.search(esperado_regex, saida_completa):
            return Resultado.OK, saida_completa.strip()
        else:
            return Resultado.FALHOU, saida_completa.strip()

    except pexpect.exceptions.TIMEOUT:
        try:
            p.close(force=True)
        except Exception:
            pass
        return Resultado.ERRO, "timeout (possível travamento / loop infinito)"
    except Exception as e:
        return Resultado.ERRO, f"exceção: {e}"


def rodar_fluxo(nome, entradas, esperado_regex_lista):
    """
    Para testes de fluxo geral (operador inválido, continuar com n/s, etc).
    entradas: lista de strings a enviar em sequência (sendline)
    esperado_regex_lista: lista de regex que devem aparecer, em ordem, na saída completa
    """
    try:
        p = pexpect.spawn(BIN_FILE, encoding="utf-8", timeout=TIMEOUT)
        saida_total = ""
        for entrada in entradas:
            idx = p.expect(["primeiro operando", "operador", "segundo operando",
                             "Resultado:", "Erro:", "Continuar", pexpect.EOF])
            saida_total += p.before + (p.after if isinstance(p.after, str) else "")
            if idx == 6:  # EOF antes do esperado
                break
            p.sendline(entrada)
        # captura o que sobrar até EOF ou timeout curto
        try:
            p.expect(pexpect.EOF, timeout=2)
            saida_total += p.before
        except pexpect.exceptions.TIMEOUT:
            pass
        p.close(force=True)
        saida_total = saida_total.replace("\x00", "").replace("\r", "")

        for regex in esperado_regex_lista:
            if not re.search(regex, saida_total):
                return Resultado.FALHOU, saida_total.strip()
        return Resultado.OK, saida_total.strip()

    except pexpect.exceptions.TIMEOUT:
        try:
            p.close(force=True)
        except Exception:
            pass
        return Resultado.ERRO, "timeout (possível travamento / loop infinito)"
    except Exception as e:
        return Resultado.ERRO, f"exceção: {e}"


# ---------------------------------------------------------------------------
# DEFINIÇÃO DOS CASOS DE TESTE
# Ajuste os regex esperados conforme o formato exato de saída do seu programa
# (ex: se seu programa imprime "8.0000" e não "8", troque o regex).
# ---------------------------------------------------------------------------

CASOS_BINARIOS_UNARIOS = [
    # (nome, op1, operador, op2 ou None, regex esperado)
    ("Soma inteira",              5, "+", 3,   r"Resultado:\s*8"),
    ("Soma decimal",              2.5, "+", 1.3, r"Resultado:\s*3\.7\d*|3\.8\d*"),
    ("Soma com negativo",         -4, "+", 2,  r"Resultado:\s*-2"),
    ("Subtração resultado negativo", 5, "-", 8, r"Resultado:\s*-3"),
    ("Multiplicação inteira",     3, "*", 4,   r"Resultado:\s*12"),
    ("Multiplicação decimal",     2.5, "*", 2, r"Resultado:\s*5"),
    ("Divisão exata",             10, "/", 4,  r"Resultado:\s*2\.5"),
    ("Divisão com dízima (1/3)",  1, "/", 3,   r"Resultado:\s*0\.3333"),
    ("Divisão por zero",          5, "/", 0,   r"Erro: divisao por zero"),

    ("Potência base/expoente positivos", 2, "^", 3, r"Resultado:\s*8"),
    ("Potência expoente zero",    5, "^", 0,   r"Resultado:\s*1"),

    ("Combinação caso normal",    5, "c", 2,   r"Resultado:\s*10"),
    ("Combinação n < r (deve dar erro)", 2, "c", 5, r"Erro: n deve ser >= r"),
    ("Combinação n == r",         5, "c", 5,   r"Resultado:\s*1"),
    ("Combinação r == 0",         5, "c", 0,   r"Resultado:\s*1"),
    ("Combinação n negativo",     -3, "c", 2,  r"Erro: operando invalido"),
    ("Combinação n não inteiro",  5.5, "c", 2, r"Erro: operando invalido"),

    ("Arranjo caso normal",       5, "a", 2,   r"Resultado:\s*20"),
    ("Arranjo n < r (deve dar erro)", 2, "a", 5, r"Erro: n deve ser >= r"),
    ("Arranjo n == r",            5, "a", 5,   r"Resultado:\s*120"),
    ("Arranjo r == 0",            5, "a", 0,   r"Resultado:\s*1"),
    ("Arranjo n negativo",        -3, "a", 2,  r"Erro: operando invalido"),

    ("Fatorial normal",           5, "!", None, r"Resultado:\s*120"),
    ("Fatorial de 0 (0!=1)",      0, "!", None, r"Resultado:\s*1"),
    ("Fatorial de 1",             1, "!", None, r"Resultado:\s*1"),
    ("Fatorial negativo",         -3, "!", None, r"Erro: operando invalido"),
    ("Fatorial não inteiro",      4.5, "!", None, r"Erro: operando invalido"),

    ("Inverso normal",            4, "i", None, r"Resultado:\s*0\.25"),
    ("Inverso de zero",           0, "i", None, r"Erro: inverso de zero"),
    ("Inverso negativo",          -2, "i", None, r"Resultado:\s*-0\.5"),

    ("Raiz quadrada exata",       9, "r", None, r"Resultado:\s*3"),
    ("Raiz quadrada não exata",   2, "r", None, r"Resultado:\s*1\.4142"),
    ("Raiz de zero",              0, "r", None, r"Resultado:\s*0"),
    ("Raiz de negativo",          -4, "r", None, r"Erro: raiz de numero negativo"),

    ("Log normal (log_10 100)",   100, "l", 10, r"Resultado:\s*2"),
    ("Log normal (log_2 8)",      8, "l", 2,   r"Resultado:\s*3"),
    ("Log base entre 0 e 1",      2, "l", 0.5, r"Resultado:"),  # deve calcular, não dar erro
    ("Log base = 1 (deve dar erro)", 100, "l", 1, r"Erro: logaritmando"),
    ("Log logaritmando = 1",      1, "l", 10,  r"Resultado:\s*0"),
    ("Log logaritmando <= 0",     0, "l", 10,  r"Erro: logaritmando"),
    ("Log logaritmando negativo", -5, "l", 10, r"Erro: logaritmando"),
    ("Log base <= 0",             10, "l", 0,  r"Erro: logaritmando"),
    ("Log base negativa",         10, "l", -2, r"Erro: logaritmando"),

    ("Próximo primo de 10",       10, "p", None, r"Resultado:\s*11"),
    ("Próximo primo de número já primo (7)", 7, "p", None, r"Resultado:\s*7"),
    ("Próximo primo de 2",        2, "p", None, r"Resultado:\s*2"),
]

CASOS_FLUXO = [
    ("Operador inválido não trava o programa",
     ["5", "%", "1", "r", "n"],
     [r"Erro: operador invalido", r"primeiro operando", r"Resultado:\s*1"]),
    ("Responder 'n' encerra o programa",
     ["5", "+", "3", "n"],
     [r"Resultado:", r"Continuar"]),
    ("Responder 's' volta ao loop para nova operação",
     ["5", "+", "3", "s", "1", "r", "n"],
     [r"Resultado:\s*8", r"primeiro operando", r"Resultado:\s*1"]),
]


def formatar_linha(nome, status, detalhe):
    cor_ok = "\033[92m"
    cor_falhou = "\033[91m"
    cor_erro = "\033[93m"
    reset = "\033[0m"
    cor = {"PASSOU": cor_ok, "FALHOU": cor_falhou}.get(status, cor_erro)
    return f"{cor}[{status:20}]{reset} {nome}\n    -> {detalhe[:200]}"


def main():
    if not montar():
        sys.exit(1)

    total = 0
    passou = 0
    falhas = []

    print("=" * 70)
    print("TESTES DE OPERAÇÕES (binárias e unárias)")
    print("=" * 70)
    for nome, op1, operador, op2, regex in CASOS_BINARIOS_UNARIOS:
        total += 1
        status, detalhe = rodar_caso(nome, op1, operador, op2, regex)
        print(formatar_linha(nome, status, detalhe))
        if status == Resultado.OK:
            passou += 1
        else:
            falhas.append(nome)

    print()
    print("=" * 70)
    print("TESTES DE FLUXO GERAL")
    print("=" * 70)
    for nome, entradas, regex_lista in CASOS_FLUXO:
        total += 1
        status, detalhe = rodar_fluxo(nome, entradas, regex_lista)
        print(formatar_linha(nome, status, detalhe))
        if status == Resultado.OK:
            passou += 1
        else:
            falhas.append(nome)

    print()
    print("=" * 70)
    print(f"RESULTADO FINAL: {passou}/{total} testes passaram")
    print("=" * 70)
    if falhas:
        print("\nTestes que falharam ou deram erro:")
        for f in falhas:
            print(f"  - {f}")


if __name__ == "__main__":
    main()