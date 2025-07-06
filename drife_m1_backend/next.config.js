/** @type {import('next').NextConfig} */
const nextConfig = { reactStrictMode: true, swcMinify: true, experimental: { serverComponentsExternalPackages: ['@mysten/sui'] }, env: { CUSTOM_KEY: process.env.CUSTOM_KEY, },}
module.exports = nextConfig
