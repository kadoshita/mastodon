today = $(shell date "+%Y%m%d")
product_name = mimikun_mastodon
cmd = sudo docker compose
cmd_web = sudo docker compose run --rm web

.PHONY : upgrade_process
upgrade_process :
	@echo "$(cmd) build --pull"
	@echo "$(cmd_web) rails db:migrate"
	@echo "$(cmd) up -d"
	@echo "$(cmd_web) bin/tootctl cache clear"
	@echo "$(cmd) up -d"

.PHONY : media_remove
media_remove :
	@echo "$(cmd_web) bin/tootctl media remove --days=30"

.PHONY : preview_cards_remove
preview_cards_remove :
	@echo "$(cmd_web) bin/tootctl preview_cards remove"
