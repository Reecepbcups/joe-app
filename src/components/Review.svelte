<script>
	export let content = '';
	let isLive = false;
	function extractTag(tag, content) {
		const regex = new RegExp(`<${tag}>(.|\n)*?<\/${tag}>`);
		const match = content.match(regex);
		const raw = match?.[0] || undefined;
		const executable =
			match?.[0].replaceAll(`<${tag}>`, '').replaceAll(`</${tag}>`, '') || undefined;
		return {
			raw,
			executable
		};
	}
	const script = extractTag('snippet', content);
	const css = extractTag('prettiez', content);
	let text = script ? content.replace(script.raw, '') : content;
	text = css ? text.replace(css.raw, '') : text;

	function injectCSS(cssString) {
		const dataUrl = 'data:text/css;base64,' + btoa(cssString);
		// Apply the CSS data URL to the document
		const link = document.createElement('link');
		link.rel = 'stylesheet';
		link.href = dataUrl;
		document.head.appendChild(link);
		console.log(css.executable)
	}
</script>

<div
	style="display: flex; flex-direction: column; align-items: center; gap: 0.1rem; margin-top: 1rem"
>
	<div>{text ?? ''}</div>
	{#if script.executable}
		<button
			on:click={() => {
				isLive = !isLive;
				eval(script.executable);
			}}>{'recklezzly run evil script'}</button
		>
		<code>
			{@html script.executable}
		</code>
	{/if}
	{#if css.executable}
		<button
			on:click={() => {
				injectCSS(css.executable);
			}}>recklezzly inject css</button
		>

		<code>
			{@html css.executable ?? ''}
		</code>
	{/if}
</div>
