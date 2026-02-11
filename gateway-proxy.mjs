#!/usr/bin/env node
/**
 * Transparent TCP proxy for Docker environments.
 *
 * Forwards 0.0.0.0:<PROXY_PORT> → 127.0.0.1:<GATEWAY_PORT>
 *
 * This makes the OpenClaw gateway see all connections as "local" (loopback),
 * avoiding the auth/device-pairing requirements that trigger when Docker's
 * bridge network makes connections appear remote.
 */
import net from "node:net";

const PROXY_PORT = parseInt(process.env.PROXY_PORT || "8080", 10);
const GATEWAY_PORT = parseInt(process.env.GATEWAY_PORT || "18789", 10);

const server = net.createServer((clientSocket) => {
  const targetSocket = net.connect(GATEWAY_PORT, "127.0.0.1");
  clientSocket.pipe(targetSocket);
  targetSocket.pipe(clientSocket);
  clientSocket.on("error", () => targetSocket.destroy());
  targetSocket.on("error", () => clientSocket.destroy());
});

server.listen(PROXY_PORT, "0.0.0.0", () => {
  console.log(`[proxy] forwarding 0.0.0.0:${PROXY_PORT} → 127.0.0.1:${GATEWAY_PORT}`);
});
