import { NextPage } from 'next';
import Head from 'next/head';
const Home: NextPage = () => {
  return (
    <div>
      <Head>
        <title>DRIFE M1 Backend</title>
        <meta name="description" content="DRIFE Milestone 1 Backend Service" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
        <h1>DRIFE Milestone 1 Backend</h1>
        <p>Backend service is running successfully!</p>
        <div style={{ marginTop: '2rem' }}>
          <h2>API Endpoints:</h2>
          <ul><li><code>POST /api/register-wallet</code></li><li><code>POST /api/batch-register-wallets</code></li></ul>
        </div>
      </main>
    </div>
  );
};
export default Home;
