/**
 * ==========================================
 * 运动康复预约系统 - 全局配置文件
 * 请根据您的Supabase项目信息修改此处
 * ==========================================
 */

const CONFIG = {
    // ================= 核心配置 (必须修改) =================
    
    // Supabase 项目URL (在 Supabase Dashboard -> Settings -> API 中找到)
    SUPABASE_URL: 'https://unwtfmhaoextwuszyqwf.supabase.co',
    
    // Supabase Anon Public Key (同上位置)
    SUPABASE_ANON_KEY: 'sb_publishable_gQ1Kgaw5YDb_l7GO8BqNtA_h2DJx_ny',
    
    // Supabase Service Role Key (用于商户端，注意保密！不要提交到公开仓库)
    // 在 Supabase Dashboard -> Settings -> API -> service_role secret
    SUPABASE_SERVICE_KEY: 'sb_secret_CW6_XyBv0-uVOjC6JHtfEQ_TSbZtlg9', 

    // ================= 商户端配置 =================
    ADMIN_PASSWORD: 'admin123', // 商户管理端登录密码，请修改为复杂密码

    // ================= 业务规则配置 (一般不需要改) =================
    // 营业时间配置
    BUSINESS_START_HOUR: 11, // 开始营业时间 (11点)
    BUSINESS_END_HOUR: 21,   // 结束营业时间 (21点，最后预约时段20:00-21:00)
    
    // 取消规则
    CANCEL_MIN_HOURS: 6,     // 提前几小时可取消
    MONTHLY_CANCEL_LIMIT: 3, // 每月最多取消次数

    // 套餐配置
    PACKAGES: {
        'A': { name: '套餐A', total: 8 },
        'B': { name: '套餐B', total: 4 }
    },

    // 时段列表 (自动生成)
    getTimeSlots: function() {
        const slots = [];
        for (let h = this.BUSINESS_START_HOUR; h < this.BUSINESS_END_HOUR; h++) {
            slots.push(`${h.toString().padStart(2,'0')}:00-${(h+1).toString().padStart(2,'0')}:00`);
        }
        return slots;
    }
};
