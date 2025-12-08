# Pin npm packages by running ./bin/importmap

# 애플리케이션 진입점
pin "application"

# Turbo (Hotwire)
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true

# Stimulus (Hotwire)
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Stimulus 컨트롤러
pin_all_from "app/javascript/controllers", under: "controllers"
