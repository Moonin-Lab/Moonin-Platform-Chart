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
		define_method("test_#{scope}_legacy_defaults") do
			job = cronjob(render(chart, prefix))
			assert_equal 'batch/v1', job['apiVersion']
			assert_equal 'moonin', job.dig('metadata', 'namespace')
			assert_equal '*/30 * * * *', job.dig('spec', 'schedule')
			assert_equal 'Forbid', job.dig('spec', 'concurrencyPolicy')
			assert_equal 'ai-sync', job.dig('spec', 'jobTemplate', 'spec', 'template', 'spec', 'serviceAccountName')
			assert_nil container(job)['envFrom']
			assert_equal %w[DATABASE_URL MOONIN_LICENSE], container(job)['env'].map { |entry| entry['name'] }
			references = container(job)['env'].map { |entry| entry.dig('valueFrom', 'secretKeyRef') }
			assert_equal [{ 'name' => 'db-secret', 'key' => 'DATABASE_URL' },
										{ 'name' => 'moonin-license', 'key' => 'MOONIN_LICENSE' }], references
		end

		define_method("test_#{scope}_legacy_model_override") do
			job = cronjob(render(chart, prefix, 'aiModel' => 'legacy-model'))
			model = container(job)['env'].find { |entry| entry['name'] == 'AI_MODEL' }
			assert_equal 'legacy-model', model['value']
			assert_nil container(job)['envFrom']
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

		define_method("test_#{scope}_secret_preserves_runtime_settings") do
			settings = { 'namespace' => 'custom-jobs', 'serviceAccountName' => 'legacy-identity',
									 'dbSecret.name' => 'custom-db', 'dbSecret.key' => 'DSN',
									 'license.existingSecret' => 'custom-license', 'license.key' => 'LICENSE' }
			legacy = cronjob(render(chart, prefix, settings))
			configured = cronjob(render(chart, prefix, settings.merge('configSecret.existingSecret' => 'installer-ai-config')))
			assert_equal [{ 'secretRef' => { 'name' => 'installer-ai-config' } }], container(configured).delete('envFrom')
			assert_equal legacy, configured
		end

		define_method("test_#{scope}_lint_modes") do
			helm('lint', chart)
			helm('lint', chart, '--set-string', "#{prefix}configSecret.existingSecret=installer-ai-config",
					 '--set-string', "#{prefix}aiModel=must-not-override-secret")
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
