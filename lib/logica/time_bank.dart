// Quanto falta no time bank; null = parado (nunca iniciado, cancelado ou já acabou).
// Mesma regra do relógio: só o início é guardado, o restante sai de `agora`.
Duration? restanteTimeBank(DateTime? inicio, Duration duracao, DateTime agora) {
  if (inicio == null) return null;
  final restante = duracao - agora.difference(inicio);
  if (restante <= Duration.zero) return null;
  // `agora` antes do início (relógio do aparelho voltou, ou "agora" fixo nos testes).
  return restante > duracao ? duracao : restante;
}
