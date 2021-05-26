desc "Anchore Security Docker Vulnerability Scan"
namespace :anchore do
  desc "Perform security vulnerability scan on docker image"
  task :scan, [:image, :image_tag, :app_name] do |t, args|
    cluster_automation = %Q{
      set +x
      curl -s https://ci-tools.anchore.io/inline_scan-latest | bash -s -- -f -r -d cmd/#{args[:app_name]}/Dockerfile -p "#{args[:image]}:#{args[:image_tag]}"
    }
    system(cluster_automation) or exit 1
  end
end

desc "Anchore Security Docker Vulnerability Scan"
namespace :anchore do
  desc "Perform security vulnerability scan on docker image by path"
  task :scan_by_path, [:image, :image_tag, :path] do |t, args|
    cluster_automation = %Q{
      set +x
      curl -s https://ci-tools.anchore.io/inline_scan-latest | bash -s -- -t 800 -d #{args[:path]}/Dockerfile -p "#{args[:image]}:#{args[:image_tag]}"
      #curl -s https://ci-tools.anchore.io/inline_scan-latest | bash -s -- -f -t 800 -d #{args[:path]}/Dockerfile -p "#{args[:image]}:#{args[:image_tag]}"
    }
    system(cluster_automation) or exit 1
  end
end

desc "Execute Anchore Security Image Scan"
namespace :anchore do
  desc "Execute Anchore Security Image Scan"
  task :image_scan, [:image, :image_tag, :app_name] do |t, args|
    anchore_image_scan = %Q{curl -s https://ci-tools.anchore.io/inline_scan-latest | bash -s -- -f -r -d cmd/#{args[:app_name]}/Dockerfile -p "#{args[:image]}:#{args[:image_tag]}"}
    system(anchore_image_scan) or exit 1
  end
end