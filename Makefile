today = $(shell date "+%Y%m%d")
product_name = mimikun_mastodon
cmd = sudo docker-compose
cmd_web = sudo docker-compose run --rm web

.PHONY : upgrade_process
upgrade_process :
	@echo "sudo docker-compose build --pull"
	@echo "sudo docker-compose run --rm web rails db:migrate"
	@echo "sudo docker-compose up -d"
	@echo "sudo docker-compose run --rm web bin/tootctl cache clear"
	@echo "sudo docker-compose up -d"

.PHONY : media_remove
media_remove :
	@echo "sudo docker-compose run --rm web bin/tootctl media remove --days=30"

.PHONY : preview_cards_remove
preview_cards_remove :
	@echo "sudo docker-compose run --rm web bin/tootctl preview_cards remove"
