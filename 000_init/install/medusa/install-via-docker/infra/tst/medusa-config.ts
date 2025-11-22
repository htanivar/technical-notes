import {loadEnv, defineConfig} from '@medusajs/framework/utils'

loadEnv(process.env.NODE_ENV || 'development', process.cwd())

module.exports = defineConfig({
        projectConfig: {
            databaseUrl: process.env.DATABASE_URL,
            http: {
                storeCors: process.env.STORE_CORS!,
                adminCors: process.env.ADMIN_CORS!,
                authCors: process.env.AUTH_CORS!,
                jwtSecret: process.env.JWT_SECRET || "supersecret",
                cookieSecret: process.env.COOKIE_SECRET || "supersecret",
            },
            databaseDriverOptions: {
                ssl: false,
                sslmode: "disable",
            }
        }
        ,
        admin: {
            vite: (config) => {
                config.server.allowedHosts = [
                    ...(config.server.allowedHosts || []),
                    "lx-dev", // Add the blocked host name here
                    "v-dev", // Add the blocked host name here
                    "dev.mobi.vdev.com", // Add the blocked host name here
                ];
                return config;
            },
        }
    }
)
