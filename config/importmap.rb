# Pin npm packages by running ./bin/importmap

# 애플리케이션 진입점
pin "application", preload: true

# Hotwire libraries from CDN
pin "@hotwired/turbo-rails", to: "https://ga.jspm.io/npm:@hotwired/turbo-rails@8.0.10/app/javascript/turbo/index.js", preload: true
pin "@hotwired/turbo", to: "https://ga.jspm.io/npm:@hotwired/turbo@8.0.12/dist/turbo.es2017-esm.js", preload: true
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Chart.js (admin 대시보드 통계)
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"

# Stimulus 컨트롤러
pin_all_from "app/javascript/controllers", under: "controllers"
