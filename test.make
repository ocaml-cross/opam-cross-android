BEST = $(shell \
  echo "hello"; \
  if ocamlfind ocamlopt 2>/dev/null; then \
    echo .native; \
  else \
    echo .byte; \
  fi \
)

default:
	echo "BEST: $(BEST)"
