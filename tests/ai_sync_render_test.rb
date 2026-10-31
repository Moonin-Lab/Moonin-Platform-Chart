require 'minitest/autorun'
require 'open3'
require 'yaml'

class AiSyncRenderTest < Minitest::Test
	ROOT = File.expand_path('..', __dir__)
	SUBCHART = File.join(ROOT, 'charts', 'Moonin-AI-Sync')
	SCOPES = { platform: [ROOT, 'moonin-ai-sync.'], subchart: [SUBCHART, ''] }.freeze

	def helm(*arguments)
		output, errors, result = Open3.capture3('helm', *arguments)
		assert result.success?, "helm #{arguments.join(' ')} failed:\n#{errors}\n#{output}"
		output
	end

	def render(chart, prefix, overrides = {})
		arguments = ['template', 'ai-sync-test', chart, '--namespace', 'arguz']
		overrides.each do |key, value|
			option = value == true || value == false ? '--set' : '--set-string'
			arguments.concat([option, "#{prefix}#{key}=#{value}"])
		end
		YAML.load_stream(helm(*arguments)).compact
	end

	def cronjob(documents)
		jobs = documents.select do |document|
			document['kind'] == 'CronJob' &&
				document.dig('metadata', 'labels', 'app.kubernetes.io/name') == 'moonin-ai-sync'
		end
		assert_equal 1, jobs.length
		jobs.first
	end

	def container(job)
		job.dig('spec', 'jobTemplate', 'spec', 'template', 'spec', 'containers').first
	end

	SCOPES.each do |scope, (chart, prefix)|
		define_method("test_#{scope}_requires_openai_secret_and_disables_service_account_token") do
			job = cronjob(render(chart, prefix))
			assert_equal 'batch/v1', job['apiVersion']
			assert_equal 'moonin', job.dig('metadata', 'namespace')
			assert_equal '*/30 * * * *', job.dig('spec', 'schedule')
			assert_equal 'Forbid', job.dig('spec', 'concurrencyPolicy')
			pod_spec = job.dig('spec', 'jobTemplate', 'spec', 'template', 'spec')
			assert_nil pod_spec['serviceAccountName']
			assert_equal false, pod_spec['automountServiceAccountToken']
			assert_equal [{ 'secretRef' => { 'name' => 'moonin-ai-sync-config' } }], container(job)['envFrom']
			assert_equal %w[DATABASE_URL MOONIN_LICENSE], container(job)['env'].map { |entry| entry['name'] }
			references = container(job)['env'].map { |entry| entry.dig('valueFrom', 'secretKeyRef') }
			assert_equal [{ 'name' => 'db-secret', 'key' => 'DATABASE_URL' },
										{ 'name' => 'moonin-license', 'key' => 'MOONIN_LICENSE' }], references
		end

		define_method("test_#{scope}_rejects_missing_configuration_secret") do
			arguments = ['template', 'ai-sync-test', chart, '--namespace', 'arguz', '--set-string', "#{prefix}configSecret.existingSecret="]
			_output, errors, result = Open3.capture3('helm', *arguments)
			refute result.success?
			assert_match(/configSecret\.existingSecret/, errors)
		end

		define_method("test_#{scope}_existing_secret_owns_model") do
			documents = render(chart, prefix, 'configSecret.existingSecret' => 'installer-ai-config',
																			'aiModel' => 'must-not-override-secret')
			job = cronjob(documents)
			assert_equal [{ 'secretRef' => { 'name' => 'installer-ai-config' } }], container(job)['envFrom']
			assert_equal %w[DATABASE_URL MOONIN_LICENSE], container(job)['env'].map { |entry| entry['name'] }
			refute documents.any? { |document| document['kind'] == 'Secret' && document.dig('metadata', 'name') == 'installer-ai-config' }
			refute_includes YAML.dump(documents), 'must-not-override-secret'
		end

		define_method("test_#{scope}_secret_preserves_runtime_settings_without_service_account") do
			settings = { 'namespace' => 'custom-jobs', 'serviceAccountName' => 'legacy-identity',
									 'dbSecret.name' => 'custom-db', 'dbSecret.key' => 'DSN',
									 'license.existingSecret' => 'custom-license', 'license.key' => 'LICENSE' }
			legacy = cronjob(render(chart, prefix, settings))
			configured = cronjob(render(chart, prefix, settings.merge('configSecret.existingSecret' => 'installer-ai-config')))
			assert_equal [{ 'secretRef' => { 'name' => 'installer-ai-config' } }], container(configured).delete('envFrom')
			container(legacy).delete('envFrom')
			assert_equal legacy, configured
			pod_spec = configured.dig('spec', 'jobTemplate', 'spec', 'template', 'spec')
			assert_nil pod_spec['serviceAccountName']
			assert_equal false, pod_spec['automountServiceAccountToken']
		end

		define_method("test_#{scope}_lint_modes") do
			helm('lint', chart)
			helm('lint', chart, '--set-string', "#{prefix}configSecret.existingSecret=installer-ai-config",
					 '--set-string', "#{prefix}dbSecret.name=custom-db")
		end
	end

	def test_platform_can_disable_cronjob
		documents = render(ROOT, 'moonin-ai-sync.', 'enabled' => false)
		has_ai_sync = documents.any? do |document|
			document['kind'] == 'CronJob' &&
				document.dig('metadata', 'labels', 'app.kubernetes.io/name') == 'moonin-ai-sync'
		end
		refute has_ai_sync
	end
end
