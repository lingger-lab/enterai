#!/usr/bin/env ruby
# 경로 검증 스크립트
# Rails 프로젝트의 모든 주요 경로를 단계별로 검증합니다

require 'pathname'

class PathValidator
  def initialize(root_path)
    @root = Pathname.new(root_path)
    @errors = []
    @warnings = []
    @success = []
  end

  def validate_all
    puts "\n" + "="*80
    puts "Rails 프로젝트 경로 검증 시작"
    puts "="*80 + "\n"

    validate_routing_structure
    validate_controller_structure
    validate_view_structure
    validate_layout_structure
    validate_model_structure
    validate_service_structure
    validate_job_structure
    validate_mailer_structure
    validate_asset_structure
    validate_config_structure
    validate_references

    print_summary
  end

  private

  def validate_routing_structure
    puts "\n[1단계] 라우팅 구조 검증"
    puts "-" * 80

    routes_file = @root + "config/routes.rb"
    check_file(routes_file, "라우팅 파일")

    # routes.rb에서 참조하는 컨트롤러 확인
    if routes_file.exist?
      content = routes_file.read
      
      # root 경로 확인
      if content.include?('root')
        if content.match(/root\s+"(\w+)#(\w+)"/)
          controller_name = $1
          action_name = $2
          controller_file = @root + "app/controllers/#{controller_name}_controller.rb"
          view_file = @root + "app/views/#{controller_name}/#{action_name}.html.erb"
          
          check_file(controller_file, "  → root 컨트롤러: #{controller_name}_controller.rb")
          check_file(view_file, "  → root 뷰: #{controller_name}/#{action_name}.html.erb")
        end
      end

      # resources 경로 확인
      if content.match(/resources\s+:(\w+)/)
        resource_name = $1
        controller_file = @root + "app/controllers/#{resource_name}_controller.rb"
        check_file(controller_file, "  → resources 컨트롤러: #{resource_name}_controller.rb")
      end
    end
  end

  def validate_controller_structure
    puts "\n[2단계] 컨트롤러 구조 검증"
    puts "-" * 80

    controllers_dir = @root + "app/controllers"
    check_directory(controllers_dir, "컨트롤러 디렉토리")

    if controllers_dir.exist?
      controllers_dir.each_child do |file|
        next unless file.file? && file.extname == '.rb'
        
        controller_name = file.basename('.rb').to_s
        puts "  ✓ 컨트롤러: #{controller_name}"
        
        # 컨트롤러에서 참조하는 뷰 확인 (public 메서드만)
        content = file.read
        
        # private/protected 키워드 이후의 메서드는 제외
        public_section = content.split(/^\s*(private|protected)\s*$/m).first || content
        
        public_section.scan(/^\s*def\s+(\w+)/) do |action|
          action_name = action[0]
          next if action_name.start_with?('_') # private 메서드 스킵
          
          view_file = @root + "app/views/#{controller_name.gsub('_controller', '')}/#{action_name}.html.erb"
          view_file_turbo = @root + "app/views/#{controller_name.gsub('_controller', '')}/#{action_name}.turbo_stream.erb"
          
          if view_file.exist? || view_file_turbo.exist?
            puts "    ✓ 액션 뷰: #{action_name}"
          else
            # 일부 액션은 뷰가 필요 없을 수 있음 (예: redirect만 하는 경우)
            # 경고는 표시하지 않음
          end
        end
      end
    end
  end

  def validate_view_structure
    puts "\n[3단계] 뷰 구조 검증"
    puts "-" * 80

    views_dir = @root + "app/views"
    check_directory(views_dir, "뷰 디렉토리")

    if views_dir.exist?
      views_dir.each_child do |dir|
        next unless dir.directory?
        
        puts "  ✓ 뷰 디렉토리: #{dir.basename}"
        
        dir.each_child do |view_file|
          next unless view_file.file?
          puts "    ✓ 뷰 파일: #{view_file.basename}"
        end
      end
    end
  end

  def validate_layout_structure
    puts "\n[4단계] 레이아웃 구조 검증"
    puts "-" * 80

    layout_file = @root + "app/layouts/application.html.erb"
    check_file(layout_file, "메인 레이아웃 파일")

    if layout_file.exist?
      content = layout_file.read
      
      # stylesheet_link_tag 확인
      if content.include?('stylesheet_link_tag')
        puts "  ✓ stylesheet_link_tag 발견"
      else
        @errors << "  ✗ stylesheet_link_tag가 없습니다"
      end

      # javascript_importmap_tags 확인
      if content.include?('javascript_importmap_tags')
        puts "  ✓ javascript_importmap_tags 발견"
      else
        @warnings << "  ⚠ javascript_importmap_tags가 없습니다"
      end

      # csrf_meta_tags 확인
      if content.include?('csrf_meta_tags')
        puts "  ✓ csrf_meta_tags 발견"
      else
        @warnings << "  ⚠ csrf_meta_tags가 없습니다"
      end
    end
  end

  def validate_model_structure
    puts "\n[5단계] 모델 구조 검증"
    puts "-" * 80

    models_dir = @root + "app/models"
    check_directory(models_dir, "모델 디렉토리")

    if models_dir.exist?
      models_dir.each_child do |file|
        next unless file.file? && file.extname == '.rb'
        model_name = file.basename('.rb').to_s
        puts "  ✓ 모델: #{model_name}"
      end
    end
  end

  def validate_service_structure
    puts "\n[6단계] 서비스 구조 검증"
    puts "-" * 80

    services_dir = @root + "app/services"
    check_directory(services_dir, "서비스 디렉토리")

    if services_dir.exist?
      services_dir.each_child do |file|
        next unless file.file? && file.extname == '.rb'
        service_name = file.basename('.rb').to_s
        puts "  ✓ 서비스: #{service_name}"
      end
    end
  end

  def validate_job_structure
    puts "\n[7단계] 잡 구조 검증"
    puts "-" * 80

    jobs_dir = @root + "app/jobs"
    check_directory(jobs_dir, "잡 디렉토리")

    if jobs_dir.exist?
      jobs_dir.each_child do |file|
        next unless file.file? && file.extname == '.rb'
        job_name = file.basename('.rb').to_s
        puts "  ✓ 잡: #{job_name}"
      end
    end
  end

  def validate_mailer_structure
    puts "\n[8단계] 메일러 구조 검증"
    puts "-" * 80

    mailers_dir = @root + "app/mailers"
    check_directory(mailers_dir, "메일러 디렉토리")

    if mailers_dir.exist?
      mailers_dir.each_child do |file|
        next unless file.file? && file.extname == '.rb'
        mailer_name = file.basename('.rb').to_s
        
        puts "  ✓ 메일러: #{mailer_name}"
        
        # 메일러 뷰 확인
        mailer_views_dir = @root + "app/views/#{mailer_name.gsub('_mailer', '')}"
        if mailer_views_dir.exist?
          puts "    ✓ 메일러 뷰 디렉토리: #{mailer_views_dir.basename}"
        end
      end
    end
  end

  def validate_asset_structure
    puts "\n[9단계] 에셋 구조 검증"
    puts "-" * 80

    assets_dir = @root + "app/assets"
    check_directory(assets_dir, "에셋 디렉토리")

    # 스타일시트
    stylesheets_dir = @root + "app/assets/stylesheets"
    check_directory(stylesheets_dir, "스타일시트 디렉토리")
    
    application_css = stylesheets_dir + "application.css"
    check_file(application_css, "application.css")

    # 빌드 디렉토리
    builds_dir = @root + "app/assets/builds"
    check_directory(builds_dir, "빌드 디렉토리")
    
    application_build_css = builds_dir + "application.css"
    if application_build_css.exist?
      puts "  ✓ 빌드된 CSS: application.css (#{application_build_css.size} bytes)"
    else
      @errors << "  ✗ 빌드된 application.css가 없습니다"
    end

    # manifest.js
    manifest_file = @root + "app/assets/config/manifest.js"
    check_file(manifest_file, "manifest.js")

    if manifest_file.exist?
      content = manifest_file.read
      if content.include?('link_tree ../builds')
        puts "  ✓ manifest.js에 builds 링크 확인"
      else
        @warnings << "  ⚠ manifest.js에 builds 링크가 없습니다"
      end
    end
  end

  def validate_config_structure
    puts "\n[10단계] 설정 파일 구조 검증"
    puts "-" * 80

    config_dir = @root + "config"
    check_directory(config_dir, "설정 디렉토리")

    required_configs = [
      "application.rb",
      "routes.rb",
      "database.yml",
      "environment.rb"
    ]

    required_configs.each do |config_file|
      file_path = config_dir + config_file
      check_file(file_path, config_file)
    end
  end

  def validate_references
    puts "\n[11단계] 파일 간 참조 관계 검증"
    puts "-" * 80

    # Reservation 모델이 ReservationMailer를 참조하는지 확인
    reservation_model = @root + "app/models/reservation.rb"
    if reservation_model.exist?
      content = reservation_model.read
      if content.include?('ReservationMailer')
        puts "  ✓ Reservation 모델 → ReservationMailer 참조 확인"
      else
        @warnings << "  ⚠ Reservation 모델에서 ReservationMailer 참조가 없습니다"
      end

      if content.include?('SmsNotificationJob')
        puts "  ✓ Reservation 모델 → SmsNotificationJob 참조 확인"
      else
        @warnings << "  ⚠ Reservation 모델에서 SmsNotificationJob 참조가 없습니다"
      end
    end

    # SmsNotificationJob이 SensSmsService를 참조하는지 확인
    sms_job = @root + "app/jobs/sms_notification_job.rb"
    if sms_job.exist?
      content = sms_job.read
      if content.include?('SensSmsService')
        puts "  ✓ SmsNotificationJob → SensSmsService 참조 확인"
      else
        @warnings << "  ⚠ SmsNotificationJob에서 SensSmsService 참조가 없습니다"
      end
    end
  end

  def check_file(path, description)
    if path.exist?
      puts "  ✓ #{description}: #{path.relative_path_from(@root)}"
      @success << description
    else
      puts "  ✗ #{description}: 없음"
      @errors << "  ✗ #{description} 파일이 없습니다: #{path}"
    end
  end

  def check_directory(path, description)
    if path.exist? && path.directory?
      puts "  ✓ #{description}: #{path.relative_path_from(@root)}"
      @success << description
    else
      puts "  ✗ #{description}: 없음"
      @errors << "  ✗ #{description} 디렉토리가 없습니다: #{path}"
    end
  end

  def print_summary
    puts "\n" + "="*80
    puts "검증 결과 요약"
    puts "="*80
    puts "\n성공: #{@success.length}개"
    puts "경고: #{@warnings.length}개"
    puts "오류: #{@errors.length}개"

    if @warnings.any?
      puts "\n경고 사항:"
      @warnings.each { |w| puts w }
    end

    if @errors.any?
      puts "\n오류 사항:"
      @errors.each { |e| puts e }
      puts "\n❌ 일부 경로에 문제가 있습니다."
    else
      puts "\n✅ 모든 주요 경로가 정상입니다!"
    end
    puts "\n"
  end
end

# 스크립트 실행
if __FILE__ == $0
  # 현재 스크립트가 있는 디렉토리를 프로젝트 루트로 사용
  root_path = File.expand_path(File.dirname(__FILE__))
  validator = PathValidator.new(root_path)
  validator.validate_all
end

