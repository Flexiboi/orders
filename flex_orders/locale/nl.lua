if Config.Lang == 'nl' then
    Language = {
        success = {
        },
        error = {
            cantorderthatmuch = "Zo veel heb ik er niet...",
        },
        progress = {
        },
        target = {
            order = 'Bestelling samen stellen',
            checkorder = 'Bestelling nakijken',
            confirmorder = 'Bestelling plaatsen',
            opencrate = 'Kist openen..',
        },
        info = {
            nolocationatthistime = 'Kom later nog maar eens terug..',
            noorder = 'Je hebt nog geen bestelling samengesteld',
            removedfromorder = 'Item is verwijderd van je bestelling',
            orderplaced = 'Bestelling ontvangeen. Je zal binnen enkele minuten de locatie ontvangen!',
        },
        command = {
        },
        menu = {
            amount = 'Aantal',
            order = {
                title = 'Bestelling',
                buy = 'Koop %s voor %s %s (Max: %s)',
                buyfree = 'Neem %s gratis mee',
                totalcost = '%s x %s voor %s %s',
                totalcostfree = '%s x %s gratis',
                cash = 'Contant',
                bank = 'Bank',
                black_money = 'Zwart geld',
                nothing = 'Niets',
                free = 'Gratis',
            },
        },
        blip = {
            location = 'Locatie',
        },
        mail = {
            sender = 'Mark',
            pickupReadyTitle = 'Bestelling',
            pickupReady = 'Je bestelling is klaar om opgehaald te worden. Heb je de locatie doorgestuurd.',
            rob = {
                sender = 'Anonymuis',
                title = 'Rare kist op locatie gezien..',
                message = 'Rare mensen en doos gespot op een locatioe. Heb je ongeveer gestuurd waar het is..'
            }
        },
        discord = '%s heeft een bestelling geplaatst',
    }
end