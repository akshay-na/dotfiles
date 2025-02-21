rules = [<const: All rules enabled>]  # Enable all rules
exclude_rules = ['rm_dir', 'fsck', 'rm']  # Exclude risky commands

wait_command = 2  # Reduce waiting time
require_confirmation = False  # Auto-correct without confirmation
no_colors = False  # Keep colors for readability
debug = False  # Disable debugging unless troubleshooting

priority = {
    'git_push': 100,  # Prioritize fixing Git push issues
    'sudo': 90,  # Prioritize sudo-related fixes
    'cd_parent': 80,  # Prioritize fixing directory movement
}

history_limit = 500  # Increase history limit for better suggestions
alter_history = True  # Apply fixed command to shell history

wait_slow_command = 10  # Reduce wait time for slow commands
slow_commands = ['lein', 'react-native', 'gradle', './gradlew', 'vagrant', 'docker-compose']

repeat = False  # Avoid repeating incorrect fixes
instant_mode = True  # Apply fixes instantly if unambiguous
num_close_matches = 5  # Improve accuracy with more suggestions

env = {'LC_ALL': 'C', 'LANG': 'C', 'GIT_TRACE': '1'}  # Keep consistent env

excluded_search_path_prefixes = ['/snap', '/nix', '/opt']  # Exclude irrelevant system paths
