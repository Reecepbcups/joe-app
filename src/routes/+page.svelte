<!-- 
    Reece Williams | Feb 2023 | Joe Webapp
    - Its JOE chain yo
-->
<script lang="ts">
	import type { Window as KeplrWindow } from '@keplr-wallet/types';
	import Review from '../components/Review.svelte'
	import type { Coin } from 'cosmjs-types/cosmos/base/v1beta1/coin';
	import { SigningStargateClient, StargateClient, type StdFee } from '@cosmjs/stargate';

	// Signing (Keplr & Ledger)
	import type { OfflineAminoSigner } from '@cosmjs/amino';
	import type { OfflineDirectSigner } from '@cosmjs/proto-signing';

	import { Tendermint34Client } from '@cosmjs/tendermint-rpc';
	import { HttpBatchClient } from '@cosmjs/tendermint-rpc/build/rpcclients';
	import { setupIbcExtension, QueryClient } from '@cosmjs/stargate';	
	// import type {HttpEndpoint} from '@cosmjs/tendermint-rpc';

	//  setupCosmWasmExtension from cosmjs
	import { setupWasmExtension, SigningCosmWasmClient } from '@cosmjs/cosmwasm-stargate';


	import toast, { Toaster, type ToastOptions } from 'svelte-french-toast';    
	const toast_style: ToastOptions = {
		position: 'top-right',
		duration: 6000,
		style: 'background: #333; color: #fff; width: 15%; font-size: 1.1rem;'
	};
	
	const CHAIN_ID = "joe-1"
	const RPC = "https://joe-rpc.polkachu.com"	
	const REVIEWS_CONTRACT_ADDRESS = "joe1nxd9d6pt7e9l2k6znclr0hkn95f60fganywkza3nqf9cvsnhzgds4yd2md"
	const WALLET_PREFIX: string = "joe"

	// User Facing Information
	let from_client: SigningStargateClient | SigningCosmWasmClient | undefined;
	let query_client: StargateClient | undefined;
	let tendermint34_client: Tendermint34Client | undefined;
	let review_text = ""
	let user_addr = ""

	// Functions
	const get_wallet_for_chain = async (
		chain_id: string
	): Promise<OfflineAminoSigner | OfflineDirectSigner> => {
		// open keplr
		const keplr = window as KeplrWindow;
		if (keplr === undefined) {			
			throw new Error('Keplr not found');
		}

		let signer = keplr.getOfflineSignerAuto;
		if (signer === undefined) {
			throw new Error('Keplr not found');
		}

		return signer(chain_id);
	};

	// // async function connectToChain
	const connect_wallet_get_balance = async () => {		
		let wallet = await get_wallet_for_chain(CHAIN_ID);
		
		if (user_addr === undefined) {
			user_addr = (await wallet.getAccounts())[0].address
		}

		if (query_client === undefined) {
			query_client = await StargateClient.connect(RPC);
		}		

		const balances = await query_client.getAllBalances(user_addr)
		return balances
	};

	let reviews: string[] = []
	const test_query = async () => {	
		if (tendermint34_client === undefined) {
			tendermint34_client = await Tendermint34Client.connect(RPC);
		}
		
		let queryClient = QueryClient.withExtensions(tendermint34_client, setupIbcExtension, setupWasmExtension);		

		const v1 = await queryClient.wasm.queryContractSmart(REVIEWS_CONTRACT_ADDRESS, {get_reviews: {}})		
		
		reviews = v1['reviews']['reviews']		
	}

	// returns an ExecuteResult
	const write_review = async () => {		
		if (review_text.length == 0) {
			toast.error(`Review text is empty`, toast_style);
			return
		}

		let wallet = await get_wallet_for_chain(CHAIN_ID);
		let address = (await wallet.getAccounts())[0].address;

		// get cosmwasm signing client
		from_client = await SigningCosmWasmClient.connectWithSigner(RPC, wallet, {
			prefix: WALLET_PREFIX
		});

		if (from_client === undefined) {
			throw new Error('from_client not found');
		}	

		// do a cosmwasm execute 

		const msg = {
			"review": {
				"text": review_text
			}
		}

		let fee: StdFee = {
			amount: [
				{
					amount: "100000",
					denom: "ujoe"
				}
			],
			gas: "500000"
		}

		await from_client.execute(
			address,
			REVIEWS_CONTRACT_ADDRESS,
			msg,
			fee		
		).then((res) => {
			console.log(res)
			toast.success(
				`Review Transaction @ height ${res.height}\n\nTxHash: ${res.transactionHash}`,
				toast_style
			);			
		}).catch((err) => {
			console.log(err)
			toast.error(`${err}`, toast_style);
		})

		// update their page text after submit
		test_query()
	}

	// call test_query on page load
	test_query()

</script>


<Toaster />

<h1>Just Joe Chain</h1>


<center>
	<ul style="width: 20%; list-style: none;">
		<li><a href="https://wetjoe.netlify.app/">Liquid Staking (pupjoes)</a>
		</li>
		<li>
			<a href="github.com/joe-chain/joe">github.com/joe-chain/joe</a>
		</li>
		<li>
			<a href="explorer.justjoe.app">explorer.justjoe.app</a>
		</li>
		<li>
			<a href="https://twitter.com/JustJoeChain">@JustJoeChain</a>
		</li>
		<li>
			<a href="https://justjoe.app/faq.txt">FAQ / INFO</a>
		</li>
		<li>
			<a href="https://sparkibc.s3.filebase.com/JOECOIN%20PROTOCOL.pdf?response-content-disposition=inline&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=CEA302ACE80DC404571A%2F20221120%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20221120T213242Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=993be66885776897f9e15e07f187175a760c6bce558b960dd0217da13b412264">JoePaper</a>
		</li>
	</ul>
	<br>

	<div id="reviews" class="div_center">
		<textarea id="review_text" name="review_text" rows="4" cols="50" placeholder="Enter review text here" bind:value={review_text}></textarea>
		<br />

		<input type="submit" value="Write A Joe Chain Review" on:click={() => write_review()} />
	</div>

	<div class="div_center">	
		<h3>Reviews</h3>	
		<ul>
		{#each reviews as review}
			<li style="">
				<Review content={review}></Review>
			</li>
		{/each}
		</ul>
	</div>
</center>


<style>
	* {
		font-family: 'Nunito Sans', sans-serif;
	}

	:global(body) {
		background-color: #ffffff;
	}

	h1,	
	h4,
	p {
		text-align: center;
		color: black;
	}

	#review_text {
		width: 100%;
	}

	.div_center {
		border: 1px solid black;
		padding: 10px;
		margin: 10px;
		max-width: 50%;
		float: none !important;
		text-align: center;
	}

	ul {
		list-style: none;
	}

	li {
		padding-bottom: 10px;
	}

	input[type='submit'] {
		background-color: #5e72e4;
		color: white;
		padding: 16px 32px;
		text-align: center;
		text-decoration: none;
		display: inline-block;
		font-size: 16px;
		margin: 4px 2px;
		cursor: pointer;
		border-radius: 8px;
	}
</style>
