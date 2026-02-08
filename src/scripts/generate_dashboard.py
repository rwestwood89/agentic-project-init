"""Generate HTML Kanban dashboard from registry data.

This script reads the registry.json file and generates a self-contained HTML
dashboard showing work items organized by stage (backlog, active, completed)
and grouped by epics.
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

from ..models.frontmatter import parse_frontmatter
from ..models.registry import Registry
from ..utils.atomic_write import atomic_write_text


def get_artifact_progress(
    item_path: str | None, project_root: Path = Path('.')
) -> dict[str, Any]:
    """Extract progress information from artifact files.

    Args:
        item_path: Path to work item directory (relative to .project/)
        project_root: Root directory of project (default: current directory)

    Returns:
        Dictionary with keys:
        - spec_status: Status of spec.md ('complete', 'in-progress', 'draft', or None)
        - design_status: Status of design.md
        - plan_status: Status of plan.md
        - phases_complete: Number of completed phases (for plan.md)
        - phases_total: Total number of phases (for plan.md)
        - owner: Owner name from artifact
        - created: Created date
        - updated: Updated date
    """
    result: dict[str, Any] = {
        'spec_status': None,
        'design_status': None,
        'plan_status': None,
        'phases_complete': None,
        'phases_total': None,
        'owner': None,
        'created': None,
        'updated': None,
    }

    if not item_path:
        return result

    base_path = project_root / '.project' / item_path

    # Check each artifact type
    for artifact_name, status_key in [
        ('spec.md', 'spec_status'),
        ('design.md', 'design_status'),
        ('plan.md', 'plan_status'),
    ]:
        artifact_path = base_path / artifact_name
        if artifact_path.exists():
            try:
                content = artifact_path.read_text(encoding='utf-8')
                frontmatter, _ = parse_frontmatter(content)

                if frontmatter:
                    # Extract status
                    status = frontmatter.get('status')
                    result[status_key] = status

                    # For plan.md, extract phases info
                    if artifact_name == 'plan.md':
                        result['phases_complete'] = frontmatter.get('phases_complete')
                        result['phases_total'] = frontmatter.get('phases_total')

                    # Extract metadata (prefer from most recent artifact)
                    if not result['owner']:
                        result['owner'] = frontmatter.get('owner')
                    if not result['created']:
                        result['created'] = frontmatter.get('created')
                    result['updated'] = frontmatter.get('updated')  # Always use latest

            except Exception:
                # Skip artifacts that can't be read
                pass

    return result


def extract_completion_date(item_path: str | None) -> str | None:
    """Extract completion date from completed item path.

    Completed items have paths like: completed/2026-02-08_item-name

    Args:
        item_path: Path to work item directory

    Returns:
        Completion date in YYYY-MM-DD format or None
    """
    if not item_path or not item_path.startswith('completed/'):
        return None

    # Extract date prefix from folder name
    folder_name = Path(item_path).name
    if '_' in folder_name:
        date_prefix = folder_name.split('_')[0]
        # Validate date format YYYY-MM-DD
        if len(date_prefix) == 10 and date_prefix.count('-') == 2:
            return date_prefix

    return None


def render_dashboard_html(registry: Registry, project_root: Path = Path('.')) -> str:
    """Render complete HTML dashboard.

    Args:
        registry: Loaded Registry instance
        project_root: Root directory of project (default: current directory)

    Returns:
        Complete HTML document as string
    """
    # Organize items by stage and epic
    stages = ['backlog', 'active', 'completed']
    organized: dict[str, dict[str, Any]] = {
        stage: {'grouped': {}, 'ungrouped': []}
        for stage in stages
    }

    # Group items by epic within each stage
    for code, item in registry.items.items():
        stage = item.stage

        # Get progress information
        progress = get_artifact_progress(item.path, project_root)
        completion_date = extract_completion_date(item.path)

        item_data = {
            'code': code,
            'title': item.title,
            'epic': item.epic,
            'path': item.path,
            **progress,
            'completion_date': completion_date,
        }

        if item.epic:
            if item.epic not in organized[stage]['grouped']:
                organized[stage]['grouped'][item.epic] = []
            organized[stage]['grouped'][item.epic].append(item_data)
        else:
            organized[stage]['ungrouped'].append(item_data)

    # Calculate epic progress
    epic_progress: dict[str, dict[str, Any]] = {}
    for epic_code, epic in registry.epics.items():
        epic_items = [
            item for item in registry.items.values()
            if item.epic == epic_code
        ]
        total = len(epic_items)
        completed = sum(1 for item in epic_items if item.stage == 'completed')

        epic_progress[epic_code] = {
            'title': epic.title,
            'status': epic.status,
            'total': total,
            'completed': completed,
            'percentage': int(completed / total * 100) if total > 0 else 0,
        }

    # Generate timestamp
    timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')

    # Render HTML
    return HTML_TEMPLATE.format(
        timestamp=timestamp,
        stages_json=json.dumps(organized),
        epics_json=json.dumps(epic_progress),
    )


# Embedded HTML template with CSS and JavaScript
HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project Dashboard</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: #f5f5f5;
            padding: 20px;
            color: #333;
        }}

        .header {{
            text-align: center;
            margin-bottom: 30px;
        }}

        .header h1 {{
            font-size: 28px;
            margin-bottom: 10px;
        }}

        .header .timestamp {{
            color: #666;
            font-size: 14px;
        }}

        .board {{
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            max-width: 1800px;
            margin: 0 auto;
        }}

        .column {{
            background: #fff;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}

        .column-header {{
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid #ddd;
        }}

        .column-header.backlog {{
            border-color: #6c757d;
        }}

        .column-header.active {{
            border-color: #007bff;
        }}

        .column-header.completed {{
            border-color: #28a745;
        }}

        .epic-group {{
            margin-bottom: 25px;
        }}

        .epic-header {{
            background: #f8f9fa;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 10px;
            border-left: 4px solid #007bff;
        }}

        .epic-code {{
            font-weight: 600;
            color: #007bff;
            font-size: 14px;
        }}

        .epic-title {{
            font-size: 16px;
            margin: 4px 0;
        }}

        .epic-progress {{
            font-size: 13px;
            color: #666;
            margin-top: 4px;
        }}

        .epic-progress-bar {{
            height: 4px;
            background: #e9ecef;
            border-radius: 2px;
            margin-top: 6px;
            overflow: hidden;
        }}

        .epic-progress-fill {{
            height: 100%;
            background: #28a745;
            transition: width 0.3s ease;
        }}

        .item-card {{
            background: #fff;
            border: 1px solid #ddd;
            border-radius: 6px;
            padding: 12px;
            margin-bottom: 10px;
            cursor: default;
            position: relative;
            transition: box-shadow 0.2s ease;
        }}

        .item-card:hover {{
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }}

        .item-code {{
            font-weight: 600;
            color: #495057;
            font-size: 13px;
            cursor: pointer;
            display: inline-block;
            padding: 2px 6px;
            border-radius: 3px;
            transition: background-color 0.2s ease;
        }}

        .item-code:hover {{
            background: #e9ecef;
        }}

        .item-code.copied {{
            background: #28a745;
            color: white;
        }}

        .item-title {{
            font-size: 15px;
            margin: 6px 0;
            font-weight: 500;
        }}

        .progress-badges {{
            display: flex;
            gap: 6px;
            margin-top: 8px;
            flex-wrap: wrap;
        }}

        .badge {{
            font-size: 11px;
            padding: 3px 8px;
            border-radius: 3px;
            font-weight: 600;
            text-transform: uppercase;
        }}

        .badge.complete {{
            background: #28a745;
            color: white;
        }}

        .badge.in-progress {{
            background: #ffc107;
            color: #333;
        }}

        .badge.draft {{
            background: #6c757d;
            color: white;
        }}

        .badge.missing {{
            background: #e9ecef;
            color: #999;
        }}

        .progress-bar-container {{
            margin-top: 8px;
        }}

        .progress-bar {{
            height: 20px;
            background: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            position: relative;
        }}

        .progress-bar-fill {{
            height: 100%;
            background: #007bff;
            transition: width 0.3s ease;
        }}

        .progress-text {{
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            font-weight: 600;
            color: #333;
        }}

        .completion-date {{
            font-size: 12px;
            color: #666;
            margin-top: 6px;
        }}

        .tooltip {{
            visibility: hidden;
            position: absolute;
            z-index: 1000;
            background: #333;
            color: white;
            padding: 10px;
            border-radius: 6px;
            font-size: 12px;
            line-height: 1.5;
            max-width: 250px;
            top: 100%;
            left: 0;
            margin-top: 8px;
            opacity: 0;
            transition: opacity 0.2s ease;
        }}

        .item-card:hover .tooltip {{
            visibility: visible;
            opacity: 1;
        }}

        .tooltip-row {{
            display: flex;
            justify-content: space-between;
            margin-bottom: 4px;
        }}

        .tooltip-label {{
            font-weight: 600;
            margin-right: 10px;
        }}

        .ungrouped-section {{
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px dashed #ddd;
        }}

        .ungrouped-header {{
            font-size: 14px;
            color: #666;
            margin-bottom: 10px;
            font-weight: 600;
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1>Project Dashboard</h1>
        <div class="timestamp">Last generated: {timestamp}</div>
    </div>

    <div class="board" id="board"></div>

    <script>
        // Data injected from Python
        const stages = {stages_json};
        const epics = {epics_json};

        // Render dashboard
        function renderDashboard() {{
            const board = document.getElementById('board');
            const stageNames = ['backlog', 'active', 'completed'];
            const stageTitles = {{
                'backlog': 'Backlog',
                'active': 'Active',
                'completed': 'Completed'
            }};

            stageNames.forEach(stage => {{
                const column = document.createElement('div');
                column.className = 'column';

                const header = document.createElement('div');
                header.className = `column-header ${{stage}}`;
                header.textContent = stageTitles[stage];
                column.appendChild(header);

                const stageData = stages[stage];

                // Render grouped items (by epic)
                Object.keys(stageData.grouped).sort().forEach(epicCode => {{
                    const epicGroup = document.createElement('div');
                    epicGroup.className = 'epic-group';

                    // Epic header
                    const epicHeader = document.createElement('div');
                    epicHeader.className = 'epic-header';

                    const epicInfo = epics[epicCode];
                    epicHeader.innerHTML = `
                        <div class="epic-code">${{epicCode}}</div>
                        <div class="epic-title">${{epicInfo.title}}</div>
                        <div class="epic-progress">${{epicInfo.completed}} / ${{epicInfo.total}} completed</div>
                        <div class="epic-progress-bar">
                            <div class="epic-progress-fill" style="width: ${{epicInfo.percentage}}%"></div>
                        </div>
                    `;
                    epicGroup.appendChild(epicHeader);

                    // Items in this epic
                    stageData.grouped[epicCode].forEach(item => {{
                        epicGroup.appendChild(renderItemCard(item));
                    }});

                    column.appendChild(epicGroup);
                }});

                // Render ungrouped items
                if (stageData.ungrouped.length > 0) {{
                    const ungroupedSection = document.createElement('div');
                    ungroupedSection.className = 'ungrouped-section';

                    const ungroupedHeader = document.createElement('div');
                    ungroupedHeader.className = 'ungrouped-header';
                    ungroupedHeader.textContent = 'No Epic';
                    ungroupedSection.appendChild(ungroupedHeader);

                    stageData.ungrouped.forEach(item => {{
                        ungroupedSection.appendChild(renderItemCard(item));
                    }});

                    column.appendChild(ungroupedSection);
                }}

                board.appendChild(column);
            }});
        }}

        function renderItemCard(item) {{
            const card = document.createElement('div');
            card.className = 'item-card';

            // Code (clickable to copy)
            const code = document.createElement('span');
            code.className = 'item-code';
            code.textContent = item.code;
            code.onclick = () => copyToClipboard(code, item.code);
            card.appendChild(code);

            // Title
            const title = document.createElement('div');
            title.className = 'item-title';
            title.textContent = item.title;
            card.appendChild(title);

            // Progress indicators
            if (item.plan_status && item.phases_total) {{
                // Implementation phase - show progress bar
                const progressContainer = document.createElement('div');
                progressContainer.className = 'progress-bar-container';

                const percentage = Math.round((item.phases_complete || 0) / item.phases_total * 100);
                progressContainer.innerHTML = `
                    <div class="progress-bar">
                        <div class="progress-bar-fill" style="width: ${{percentage}}%"></div>
                        <div class="progress-text">${{item.phases_complete || 0}} / ${{item.phases_total}}</div>
                    </div>
                `;
                card.appendChild(progressContainer);
            }} else {{
                // Definition phase - show badges
                const badges = document.createElement('div');
                badges.className = 'progress-badges';

                ['spec', 'design', 'plan'].forEach(artifact => {{
                    const status = item[`${{artifact}}_status`];
                    const badge = document.createElement('span');
                    badge.className = `badge ${{status || 'missing'}}`;
                    badge.textContent = artifact;
                    badges.appendChild(badge);
                }});

                card.appendChild(badges);
            }}

            // Completion date
            if (item.completion_date) {{
                const completionDate = document.createElement('div');
                completionDate.className = 'completion-date';
                completionDate.textContent = `Completed: ${{item.completion_date}}`;
                card.appendChild(completionDate);
            }}

            // Tooltip
            const tooltip = document.createElement('div');
            tooltip.className = 'tooltip';
            tooltip.innerHTML = `
                ${{item.owner ? `<div class="tooltip-row"><span class="tooltip-label">Owner:</span><span>${{item.owner}}</span></div>` : ''}}
                ${{item.created ? `<div class="tooltip-row"><span class="tooltip-label">Created:</span><span>${{item.created}}</span></div>` : ''}}
                ${{item.updated ? `<div class="tooltip-row"><span class="tooltip-label">Updated:</span><span>${{item.updated}}</span></div>` : ''}}
            `;
            card.appendChild(tooltip);

            return card;
        }}

        function copyToClipboard(element, text) {{
            navigator.clipboard.writeText(text).then(() => {{
                element.classList.add('copied');
                setTimeout(() => {{
                    element.classList.remove('copied');
                }}, 1000);
            }});
        }}

        // Initialize dashboard
        renderDashboard();
    </script>
</body>
</html>
"""


def main() -> int:
    """Main entry point for generate-dashboard script.

    Returns:
        Exit code: 0 (success), 1 (input error), 2 (state error)
    """
    parser = argparse.ArgumentParser(
        description='Generate HTML Kanban dashboard from registry'
    )
    parser.add_argument(
        '--output',
        default='.project/dashboard.html',
        help='Output path for HTML dashboard (default: .project/dashboard.html)'
    )
    parser.add_argument(
        '--project-root',
        default='.',
        help='Project root directory (default: current directory)'
    )

    args = parser.parse_args()

    try:
        # Determine project root
        project_root = Path(args.project_root)

        # Check if registry exists
        registry_path = project_root / '.project' / 'registry.json'
        if not registry_path.exists():
            print("Error: registry.json not found", file=sys.stderr)
            print(json.dumps({'error': 'registry_not_found'}))
            return 2

        # Load registry
        registry = Registry(registry_path)
        try:
            registry.load()
        except (json.JSONDecodeError, ValueError) as e:
            print(f"Error: Invalid registry format: {e}", file=sys.stderr)
            print(json.dumps({'error': 'invalid_registry', 'detail': str(e)}))
            return 2

        # Generate dashboard HTML
        html_content = render_dashboard_html(registry, project_root)

        # Write to file atomically
        output_path = Path(args.output)
        if not output_path.is_absolute():
            output_path = project_root / output_path
        atomic_write_text(html_content, output_path)

        # Success output
        result = {
            'output': str(output_path),
            'items_count': len(registry.items),
            'epics_count': len(registry.epics),
        }
        print(json.dumps(result))
        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        print(json.dumps({'error': 'generation_failed', 'detail': str(e)}))
        return 2


if __name__ == '__main__':
    sys.exit(main())
