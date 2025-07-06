import React from 'react'
import Head from 'next/head'
import styles from '../styles/Home.module.css'

export default function Home() {
  return (
    <div className={styles.container}>
      <Head>
        <title>DRIFE M2 Ride Sync Backend</title>
        <meta name="description" content="DRIFE M2 Ride Sync Backend API" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <h1 className={styles.title}>
          DRIFE M2 Ride Sync Backend
        </h1>

        <p className={styles.description}>
          API for interacting with the DRIFE M2 Ride Sync smart contract
        </p>

        <div className={styles.grid}>
          <div className={styles.card}>
            <h2>API Endpoints</h2>
            <ul>
              <li><code>/api/assign-role</code> - Assign role to a user</li>
              <li><code>/api/revoke-role</code> - Revoke role from a user</li>
              <li><code>/api/request-ride</code> - Request a new ride</li>
              <li><code>/api/match-driver</code> - Match a driver to a ride</li>
              <li><code>/api/complete-ride</code> - Mark a ride as completed</li>
              <li><code>/api/cancel-ride</code> - Cancel a ride</li>
              <li><code>/api/archive-ride</code> - Archive a completed/cancelled ride</li>
              <li><code>/api/contract-control</code> - Pause/unpause the contract</li>
              <li><code>/api/emit-ride-info</code> - Emit ride info for indexers</li>
            </ul>
          </div>
        </div>
      </main>

      <footer className={styles.footer}>
        <p>DRIFE M2 Ride Sync Backend</p>
      </footer>
    </div>
  )
} 